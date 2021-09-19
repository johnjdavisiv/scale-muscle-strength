# Scale muscle strength

Use height and body mass to automatically adjust strength of the muscles in an OpenSim model using the MRI-derived regression equations in Handsfield et al. 2014.

Citation: 
>Handsfield, G.G., Meyer, C.H., Hart, J.M., Abel, M.F. and Blemker, S.S., 2014. Relationships of 35 lower limb muscles to height and body mass quantified using MRI. Journal of Biomechanics, 
47(3), pp.631-638.
 
This MATLAB function uses the regression equations of Handsfield et al. (stored in `muscle_scaling_coefficients.csv`; these are derived from Supplementary Table 3 in the paper) to scale the maximum isometric force of lower-body muscles in an OpenSim model.  The Handsfield equations predict muscle volume in cm^3 using the height-mass product (height in meters, mass in kg).  

PCSA is just muscle volume divided by muscle fiber length (see e.g., Uchida and Delp 2020 p. 121), so we can take the predicted muscle volume (in cm^3), divide it by optimal fiber length (in cm), and multiply by the specific tension of muscle (61 N/cm^2 in this function) to get the maximum isometric force for each muscle.  

This function was specifically developed for musculoskeletal models derived from Rajagopal et al.'s 2016 lower-body model. The muscle names in the model must **exactly** match the `model_muscle_name` column in the csv. You'll need to modify this csv or the code if your model has different muscles, or differently-named muscles. 