#Conda paketleri nerede ve hangi sırayla aradığını görmek amacıyla kanal ayarlarını yazdırıyoruz.
conda config --show channels

#Ortamın nasıl çalıştığını görmek amacıyla 'deneme' adlı, alıştırma için oluşturup sonra silinecek küçük ortam kuruldu.
conda create -y -n deneme seqkit

#Ortamın gerçekten ayrı bir klasör olduğunu görmek için ortamı etkinleştiriyor, aracın nereden çalıştığına bakıyor, ardından ortamı kapatıp aynı soruyu yeniden soruyoruz.
conda activate deneme
which seqkit
seqkit version
conda deactivate
which seqkit

#Bu adımda, variants-ready ortamını etkinleştirmeden varyant analizinde kullanılacak dört aracın sürümlerini kontrol ediyoruz.
conda list -n variants-ready | grep -E "^(# Name|bcftools|samtools|bwa|htslib) "

#Proje ilerledikçe genişleyebilir. Bu adımda, deneme ortamında ikinci küçük bir FASTQ aracı olan seqtk'yi ekliyoruz.
conda install -y -n deneme seqtk


#Bu adımda, ortamı başka bir bilgisayarda yeniden kurabilmek için tanımını envs/deneme.yml dosyasına kaydedip içeriğini inceliyoruz.
conda env export -n deneme --from-history > envs/deneme.yml
cat envs/deneme.yml

#Alıştırmayı tamamlamak amacıyla 'deneme' ortamını siliyor ve ortam listesine yeniden bakıyoruz.
conda env remove -y -n deneme
conda env list

# Dosyanın içeriği kontrol edilir ve Conda ortamı (ortam ayrıntıları yazılır)
# bu dosyadan oluşturulur. Komutlar scripts/day1.sh dosyasına eklenir.
cat envs/rnaseq.yml

#evs kurulur.
conda env create -f envs/rnaseq.yml

# Yeni Conda ortamı etkinleştirilir ve dört aracın sürümleri
# kontrol edilir. Ortam, Terminal boyunca etkin kalır.
conda activate rnaseq
salmon --version
fastp --version
fastqc --version
multiqc --version

#Envrionment file check
bash check/day1-envs.sh

#Git push 
git add envs/ scripts/
git commit -m "Day 1: environment files"
git push

#Retrieve Data/Download
curl -L -o data/airway_samples.csv https://github.com/onedimkurt/bioinfo-workshop/releases/download/data-v1/airway_samples.csv
head -3 data/airway_samples.csv

#Setup day1 extra data
bash setup/day1.sh


ls -lh data/ | head -30
ls data/quant

#Check the fastq read
zcat data/SRR1039508_1.sub.fastq.gz | head -8

#check the road count 
for f in data/SRR10395*.sub.fastq.gz; do
  echo "$f $(( $(zcat "$f" | wc -l) / 4 )) reads"
done
zcat data/SRR1039508_1.sub.fastq.gz | head -4000 | awk 'NR % 4 == 2 { print length($0) }' | sort | uniq -c

#FastQC
mkdir -p results/fastqc
fastqc -t 2 --extract -o results/fastqc data/SRR1039508_1.sub.fastq.gz data/SRR1039508_2.sub.fastq.gz data/SRR1039509_1.sub.fastq.gz data/SRR1039509_2.sub.fastq.gz

#FASTp / second qc
mkdir -p results/fastp
for s in SRR1039508 SRR1039509; do
  fastp -i data/${s}_1.sub.fastq.gz -I data/${s}_2.sub.fastq.gz \
        -o results/fastp/${s}_1.trim.fastq.gz -O results/fastp/${s}_2.trim.fastq.gz \
        --detect_adapter_for_pe -w 2 \
        -j results/fastp/${s}.fastp.json -h results/fastp/${s}.fastp.html
done

#FASTQC
mkdir -p results/fastqc_trimmed
fastqc -t 2 --extract -o results/fastqc_trimmed results/fastp/*.trim.fastq.gz

#Salmon index
salmon index -t data/gencode.v50.transcripts.chr.fa.gz -i results/salmon_index --gencode -p 2

#Salmon quant 
for s in SRR1039508 SRR1039509; do
  salmon quant -i results/salmon_index -l A \
    -1 results/fastp/${s}_1.trim.fastq.gz -2 results/fastp/${s}_2.trim.fastq.gz \
    -p 2 -o results/salmon/${s}
done

grep -o '"percent_mapped": [0-9.]*' results/salmon/*/aux_info/meta_info.json
grep -h '"expected_format"\|"strand_mapping_bias"' results/salmon/*/lib_format_counts.json
head -5 results/salmon/SRR1039508/quant.sf
for d in data/quant/SRR*; do
  echo "$(basename $d) $(grep -o '"percent_mapped": [0-9.]*' $d/aux_info/meta_info.json)"
done

#multiQC
multiqc -q -o results/multiqc results/fastqc results/fastqc_trimmed results/fastp results/salmon
awk -F'\t' 'NR == 1 || $2 != ""' results/multiqc/multiqc_data/multiqc_general_stats.txt | cut -f1-4

#Git commit
git add scripts/
git commit -m "Day 1: reads to counts"
git push


