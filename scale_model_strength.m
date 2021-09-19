function model = scale_model_strength(base_code_path, model, height_m, str_scale_factor)
%{

Use height and weight to scale the maximum isometric force of each muscle in a Rajagopal 2016-type 
model using regression equations from Handsfield et al.

John J Davis IV
Indiana University Biomechanics Lab

Citation
--------

Handsfield, G.G., Meyer, C.H., Hart, J.M., Abel, M.F. and Blemker, S.S., 2014. Relationships of 35 
lower limb muscles to height and body mass quantified using MRI. Journal of Biomechanics, 
47(3), pp.631-638.


Inputs
------

base_code_path: string 
    absolute path to where this function is located. Only needed to read the coefficient csv

model: instance of OpenSim Model() class 
    Scaled model whose strength we would like to change. Make sure the model's mass is set correctly

height_m: float
    Height of subject, in meters

str_scale_factor: float
    "Fudge" factor to multiply all muscle strengths by. E.g. if str_scale_factor is 1.25, muscle
    strength will be scaled by the Handsfield et al. equations, then increased by 25%. Recommend 1.0
    as a good starting point for most cases.

Returns
-------

model: instance of OpenSim Model() class 
    Same model as input, now with updated muscle strength parameters

Notes
-----

The regression equations of Handsfield et al. predict muscle volume in cm^3, using the height-mass
product (height in meters, mass in kg). This function uses the optimal fiber length of each muscle
to calculate the predicted physiological cross-sectional area of each muscle, since PCSA is just
muscle volume divided by muscle fiber length (e.g., Uchida and Delp 2020 p. 121). PCSA is then
multiplied by the specific tension of muscle, 61 N/cm^2 in this function (can be changed if
desired) to get the maximum isometric force for each muscle. This function was specifically
developed for musculoskeletal models derived from Rajagopal et al.'s 2016 lower-body model, so
adjustments might be needed for other model types. See Rajagopal et al. 2016 and Arnold et al. 2010
for info on dividing out forces across muscles represented by multiple musculotendon actuators (e.g.
the glute max).

%}


%Scale strength of model based on Handsfield et al regression equations
import org.opensim.modeling.*

%Specifict tension in N/cm2, same as Rajagopal (60), Arnold (61)
specific_tension = 61; 

%Get predictive coefs from Handsfield et al 2014
muscle_table_path = [base_code_path, '\muscle_scaling_coefficients.csv']; 
%relative paths do not always work with OpenSim API loaded...

muscle_table = readtable(muscle_table_path); 
mass_kg = model.getTotalMass(model.initSystem()); %.initSystem might or might not be needed here
height_x_mass = height_m*mass_kg;

muscles = model.getMuscles();
n_muscles = muscles.getSize();

%OSim is zero-indexed
for a=0:n_muscles-1
    this_muscle = muscles.get(a);
    
    %Get fiber length, in cm
    L0_f = this_muscle.getOptimalFiberLength()*100;
    %Original (unscaled) Fmax
    fmax_old = this_muscle.getMaxIsometricForce();
    
    %Index into coefs table
    muscle_name = char(this_muscle.getName());
    muscle_ix = matches(muscle_table.model_muscle_name, muscle_name);
    b_intercept = muscle_table.b_intercept(muscle_ix);
    b_slope = muscle_table.b_slope(muscle_ix);
    m_volume_prop = muscle_table.volume_proportion(muscle_ix);
    
    %Predict muscle volume in cm3, adjusting for volume fraction 
    pred_volume = m_volume_prop*(b_intercept + b_slope*height_x_mass);
    pcsa = pred_volume/L0_f;
    fmax_new = pcsa*specific_tension*str_scale_factor;
    
    %Update strength
    this_muscle.setMaxIsometricForce(fmax_new);
    
    %Print sanity check
    fprintf('Scaled generic %s strength by %.1f%%\n', ...
        muscle_name, fmax_new/fmax_old*100);
end

disp('Muscle strength successfully scaled!');
