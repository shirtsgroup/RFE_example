#!/bin/bash

#Set total number of Lambda states
#Note will also need to change directories for production run
Lambda_tot=6

#Need to add source to your gromacs installation and mutation forcefields first
export GMXLIB=~/doc/SH2/pmx/pmx/data/mutff45

# Set some environment variables
HOME=`pwd`
echo "Home directory set to $HOME"
MDP=$HOME/MDP
echo ".mdp files are stored in $MDP"

##############################
#     SET-UP SYSTEM BOX      #
##############################

mkdir solvate
cd solvate

gmx editconf -f ../../input_data/hybrid.pdb -o box.gro -bt dodecahedron -d 1.0

gmx solvate -cp box.gro -p ../../input_data/hybrid.top -o solv.gro -cs

gmx grompp -f ions.mdp -c solv.gro -p ../../input_data/hybrid.top -o ions.tpr

gmx genion -s ions.tpr -o ions.gro -p ../../input_data/hybrid.top -pname NA -nname CL -neutral

cd $HOME

##############################
# ENERGY MINIMIZATION STEEP  #
##############################
echo "Starting minimization for Lambda 0"

mkdir EM
cd EM

# Iterative calls to grompp and mdrun to run the simulations

gmx grompp -f $MDP/em.mdp -c ../solvate/ions.gro -p ../../input_data/hybrid.top -o min.tpr -maxwarn 1

gmx mdrun -deffnm min

#Exit if files are not written properly
if test ! -f "min.gro"; then
	echo "Error with EM step"
	exit 1
fi

sleep 10

#####################
# NVT EQUILIBRATION #
#####################
echo "Starting constant volume equilibration..."

cd ../
mkdir NVT
cd NVT

gmx grompp -f $MDP/nvt.mdp -c ../EM/min.gro -r ../EM/min.gro -p ../../input_data/hybrid.top -o nvt.tpr -maxwarn 1

gmx mdrun -deffnm nvt

echo "Constant volume equilibration complete."
#Exit if files are not written properly
if test ! -f "nvt.gro"; then
	echo "Error with NVT step on Lambda $MUT"
	exit 1
fi

sleep 10

#####################
# NPT EQUILIBRATION #
#####################
echo "Starting constant pressure equilibration..."

cd ../
mkdir NPT
cd NPT

gmx grompp -f $MDP/npt.mdp -c ../NVT/nvt.gro -r ../NVT/nvt.gro -p ../../input_data/hybrid.top -t ../NVT/nvt.cpt -o npt.tpr -maxwarn 1

gmx mdrun -deffnm npt -ntmpi 2 -ntomp 8

#Exit if files are not written properly
if test ! -f "npt.gro"; then
	echo "Error with NPT step on Lambda $MUT"
	exit 1
fi

echo "Constant pressure equilibration complete."

sleep 10

cd $HOME

#Set new directory for Lambda MDP files
MDP=$HOME/MDP_Lambda
echo "Lambda .mdp files are stored in $MDP"

mkdir equil_l
cd equil_l

for (( i=0; i<$Lambda_tot; i++ ))
do
	LAMBDA=$i
	# A new directory will be created for each value of lambda and
	# at each step in the workflow for maximum organization.

	mkdir Lambda_$LAMBDA
	cd Lambda_$LAMBDA

	##############################
	# ENERGY MINIMIZATION STEEP  #
	##############################
	echo "Starting minimization for lambda = $LAMBDA..."

	mkdir EM
	cd EM

	# Iterative calls to grompp and mdrun to run the simulations
	#Only run minimization if it has not been done
	if test ! -f "min_$LAMBDA.gro"; then
		gmx grompp -f $MDP/em_steep_$LAMBDA.mdp -c ../../../NPT/npt.gro -p ../../../../input_data/hybrid.top -o min_$LAMBDA.tpr -maxwarn 2

		gmx mdrun -deffnm min_$LAMBDA
	fi

	#Exit if files are not written properly
	if test ! -f "min_$LAMBDA.gro"; then
		echo "Error with EM step on lambda = $LAMBDA"
		exit 1
	fi

	sleep 10

	#####################
	# NVT EQUILIBRATION #
	#####################
	echo "Starting constant volume equilibration..."

	cd ../
	mkdir NVT
	cd NVT

	#Only run nvt equilibration if it has not been done
	if test ! -f "nvt_$LAMBDA.gro"; then
		gmx grompp -f $MDP/nvt_$LAMBDA.mdp -c ../EM/min_$LAMBDA.gro -r ../EM/min_$LAMBDA.gro -p ../../../../input_data/hybrid.top -o nvt_$LAMBDA.tpr -maxwarn 3

		gmx mdrun -deffnm nvt_$LAMBDA
	fi
	echo "Constant volume equilibration complete."

    	#Exit if files are not written properly
        if test ! -f "nvt_$LAMBDA.gro"; then
		echo "Error with NVT step on lambda = $LAMBDA"
		exit 1
	fi

	sleep 10

	#####################
	# NPT EQUILIBRATION #
	#####################
	echo "Starting constant pressure equilibration..."

	cd ../
	mkdir NPT
	cd NPT

	#Only run npt equilibration if it has not been done
	if test ! -f "npt_$LAMBDA.gro"; then
		gmx grompp -f $MDP/npt_$LAMBDA.mdp -c ../NVT/nvt_$LAMBDA.gro -r ../NVT/nvt_$LAMBDA.gro -p  ../../../../input_data/hybrid.top -t ../NVT/nvt_$LAMBDA.cpt -o npt_$LAMBDA.tpr -maxwarn 3
		
		gmx mdrun -deffnm npt_$LAMBDA
	fi
	
	#Exit if files are not written properly
	if test ! -f "npt_$LAMBDA.gro"; then
		echo "Error with NPT step on lambda = $LAMBDA"
		exit 1
	fi

	echo "Constant pressure equilibration complete."

	cd $HOME
done

######################
#   Production Run   #
######################

mkdir prod_l
cd prod_l

for (( i=0; i<$Lambda_tot; i++ ))
do
	LAMBDA=$i

	mkdir Lambda_$LAMBDA
	cd Lambda_$LAMBDA

	gmx grompp -f $MDP/md_$LAMBDA.mdp -c ../../equil_l/Lambda_$LAMBDA/NPT/npt_$LAMBDA.gro -p ../../../input_data/hybrid.top -t ../../equil_l/Lambda_$LAMBDA/NPT/npt_$LAMBDA.cpt -o md.tpr -maxwarn 2

	cd ../
done

mpirun -np 6 gmx_mpi mdrun -replex 100 -multidir Lambda_0 Lambda_1 Lambda_2 Lambda_3 Lambda_4 Lambda_5 -deffnm md -dhdl dhdl.xvg



