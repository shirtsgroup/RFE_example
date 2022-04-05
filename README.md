# RFE_example
A example of the workflow used to complete RFE calculations set up with PMX and run using GROMACS

## Step 1: Determine you system of interest
For this example we are using a protein - protein binding system although the procedure is essentially the same for a protein ligand system. You will need to obtain starting structures which for this example a crystal structure was available for the protein-protein complex. You then seperate the two moleucles into different PDB files in order to preform the mutations.

## Step 2: Generate the hybrid topology
Unless you are intending to examine the mutation on a protein which contains non-standard residues (like phoshorylated residues) you can imply use the PMX webserver to perform the mutations.

## Step 3: Solvation FE

## Step 4: Complex FE

## Step 5: Combine for total FE difference with the mutation

For RFE analysis visit the following [repository](https://github.com/ajfriedman22/Free_Energy)
