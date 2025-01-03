# *OSEA* Mobile

<img src="/assets/icons/fore.png?raw=true" alt="icon" width="200"/>

Flutter app for offline bird identification

For the detecting task, we uses pretrained model `ssd mobilenet`.

For the classification task, `ResNet34` model structure was adopted, take [MetaFGNet/L_Bird_pretrain/checkpoints](https://drive.google.com/drive/folders/1gsct7uWHYPfmNmFvLVHlgFqKOcoQRzs9) as a pretrained model, trained on [DongNiao DIB-10K](https://www.researchgate.net/publication/344639013) using [Gorilla-Lab-SCUT/MetaFGNet](https://github.com/Gorilla-Lab-SCUT/MetaFGNet).

Structure of `assets` folder:
- assets
    - icons (all in git)
    - db
      - [avonet.db](https://github.com/sun-jiao/osea_mobile/releases/download/assets/avonet.db)
    - labels
      - [bird_info.json](https://github.com/sun-jiao/osea_mobile/releases/download/assets/bird_info.json)
    - models
      - bird_model.onnx (the [quantized onnx version](https://github.com/sun-jiao/osea_mobile/releases/download/assets/bird_model.onnx) of [model20240824.pth](https://github.com/sun-jiao/MetaFGNet/releases))
      - ssd_mobilenet.onnx (the [quantized version](https://github.com/sun-jiao/osea_mobile/releases/download/assets/ssd_mobilenet.onnx) of pre-trained model from [onnx modelzoo](https://github.com/onnx/models/tree/main/validated/vision/object_detection_segmentation/ssd-mobilenetv1))
