conda config --show channels
conda create -y -n deneme seqkit
conda activate deneme
which seqkit
seqkit version
conda deactivate
which seqkit
conda activate deneme
conda deactivate
#Tool Inspect, extend, export
conda list -n variants-ready | grep -E "^(# Name|bcftools|samtools|bwa|htslib) "
#Dowloading a tool or package ibto an env, not activated yet.
conda install -y -n deneme seqtk
conda activate deneme
which seqtk
conda deactivate
which seqtk

#Check the deneme env's history
conda env export -n deneme --from-history > envs/deneme.yml
cat envs/deneme.yml

#Removing on environment 
conda env remove -y -n deneme
conda env list


