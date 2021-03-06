#!/bin/bash
echo "MXNet Model Quantization Performance"
echo "Testing FP32 base models"
echo "Installing mxnet-mkl 1.5.0b20190623"
pip install --pre mxnet-mkl==1.5.0b20190623
echo "Downloading source code from incubator-mxnet repo"
git clone https://github.com/apache/incubator-mxnet
cd incubator-mxnet
git checkout f44f6cfbe752fd8b8036307cecf6a30a30ad8557

export KMP_AFFINITY=granularity=fine,noduplicates,compact,1,0
export vCPUs=`cat /proc/cpuinfo | grep processor | wc -l`
export OMP_NUM_THREADS=$((vCPUs / 2))
echo "Test with OMP_NUM_THREADS="$OMP_NUM_THREADS

# Reduce remote memory access
export NNVM_EXEC_MATCH_RANGE=1
unset MXNET_SUBGRAPH_BACKEND

echo "=========test image classification models=========="
cd ./example/quantization
echo "=============resnet50_v1==============="
echo "1. calibrating resnet50_v1 with calib-mode=naive, use 5 batches to do calibration"
python imagenet_gen_qsym_mkldnn.py --model=resnet50_v1 --num-calib-batches=5 --calib-mode=naive
echo "2. testing throughput of fp32 resnet50_v1"
python imagenet_inference.py --symbol-file=./model/resnet50_v1-symbol.json --batch-size=64 --num-inference-batches=500 --ctx=cpu --benchmark=True
echo "3. testing latency of fp32 resnet50_v1"
python imagenet_inference.py --symbol-file=./model/resnet50_v1-symbol.json --batch-size=1 --num-inference-batches=500 --ctx=cpu --benchmark=True
echo "=============resnet101_v1==============="
echo "1. calibrating resnet101_v1 with calib-mode=naive, use 5 batches to do calibration"
python imagenet_gen_qsym_mkldnn.py --model=resnet101_v1 --num-calib-batches=5 --calib-mode=naive
echo "2. testing throughput of fp32 resnet101_v1"
python imagenet_inference.py --symbol-file=./model/resnet101_v1-symbol.json --batch-size=64 --num-inference-batches=500 --ctx=cpu --benchmark=True
echo "3. testing latency of fp32 resnet101_v1"
python imagenet_inference.py --symbol-file=./model/resnet101_v1-symbol.json --batch-size=1 --num-inference-batches=500 --ctx=cpu --benchmark=True
echo "=============mobilenet1.0==============="
echo "1. calibrating mobilenet1.0 with calib-mode=naive, use 5 batches to do calibration"
python imagenet_gen_qsym_mkldnn.py --model=mobilenet1.0 --num-calib-batches=5 --calib-mode=naive
echo "2. testing throughput of fp32 mobilenet1.0"
python imagenet_inference.py --symbol-file=./model/mobilenet1.0-symbol.json --batch-size=64 --num-inference-batches=500 --ctx=cpu  --benchmark=True
echo "3. testing latency of fp32 mobilenet1.0"
python imagenet_inference.py --symbol-file=./model/mobilenet1.0-symbol.json --batch-size=1 --num-inference-batches=500 --ctx=cpu  --benchmark=True
echo "=============inceptionv3==============="
echo "1. calibrating inceptionv3 with calib-mode=naive, use 5 batches to do calibration"
python imagenet_gen_qsym_mkldnn.py --model=inceptionv3 --image-shape=3,299,299 --num-calib-batches=5 --calib-mode=naive
echo "2. testing throughput of fp32 inceptionv3"
python imagenet_inference.py --symbol-file=./model/inceptionv3-symbol.json --image-shape=3,299,299 --batch-size=64 --num-inference-batches=500 --ctx=cpu  --benchmark=True
echo "3. testing latency of fp32 inceptionv3"
python imagenet_inference.py --symbol-file=./model/inceptionv3-symbol.json --image-shape=3,299,299 --batch-size=1 --num-inference-batches=500 --ctx=cpu  --benchmark=True

echo "=========test image detection models=========="
echo "==============SSD VGG16================"
echo "1. downloading model"
cd ../ssd
cd model/ && wget http://apache-mxnet.s3-accelerate.dualstack.amazonaws.com/gluon/models/ssd_vgg16_reduced_300-dd479559.zip
unzip ssd_vgg16_reduced_300-dd479559.zip && mv ssd_vgg16_reduced_300-dd479559.params ssd_vgg16_reduced_300-0000.params && mv ssd_vgg16_reduced_300-symbol-dd479559.json ssd_vgg16_reduced_300-symbol.json
cd ../data && wget http://apache-mxnet.s3-accelerate.dualstack.amazonaws.com/gluon/dataset/ssd-val-fc19a535.zip
unzip ssd-val-fc19a535.zip && mv ssd-val-fc19a535.idx val.idx && mv ssd-val-fc19a535.lst val.lst && mv ssd-val-fc19a535.rec val.rec
cd ..
echo "2. testing throughput of fp32 SSD VGG16"
python benchmark_score.py --batch_size=224 --deploy --prefix=./model/ssd_
echo "3. testing latency of fp32 SSD VGG16"
python benchmark_score.py --batch_size=1 --deploy --prefix=./model/ssd_
