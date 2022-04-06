# RFE_example
A example of the workflow used to complete RFE calculations set up with PMX and run using GROMACS

## Step 1: Determine you system of interest
For this example we are using a protein - protein binding system although the procedure is essentially the same for a protein ligand system. You will need to obtain starting structures which for this example a crystal structure was available for the protein-protein complex. You then seperate the two moleucles into different PDB files in order to preform the mutations.

## Step 2: Generate the hybrid topology
Unless you are intending to examine the mutation on a protein which contains non-standard residues (like phoshorylated residues) you can imply use the [PMX webserver](http://pmx.mpibpc.mpg.de/) to perform the mutations. Alternatively the functions can be downloaded from PMX [Github](https://github.com/deGrootLab/pmx) to allow for forcefield modifications.

## Step 3: Solvation FE
The solvation FE protocol is outlined above.

## Step 4: Complex FE
This step requires repeating the steps associated with the solvation FE with the exception that a complex topology and gro files will need to be generated. The method of generating the complex files will depend on the molecule your protein will be binding.

## Step 5: Combine for total FE difference with the mutation
The analysis scripts for generating a value of ΔG for the solvation and complex FE can be found in this [repository](https://github.com/ajfriedman22/Free_Energy). The total ΔΔG = ΔG of solvation - ΔG of complex.
