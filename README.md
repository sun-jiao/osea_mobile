# Flutter bird ID (temporary name)

<img src="/assets/icons/fore.png?raw=true" alt="icon" width="200"/>

Flutter app for offline bird identification

For the detecting task, we uses pretrained model `yolo11n`.

For the classification task, `ResNet34` model structure was adopted, take [MetaFGNet/L_Bird_pretrain/checkpoints](https://drive.google.com/drive/folders/1gsct7uWHYPfmNmFvLVHlgFqKOcoQRzs9) as a pretrained model, trained on [DongNiao DIB-10K](https://www.researchgate.net/publication/344639013).

Structure of `assets` folder:
- assets
    - icons (all in git)
    - labels
        - [bird_info.json](https://github.com/sun-jiao/MetaFGNet/releases)
        - [yolo_labels.txt](https://github.com/abdelaziz-mahdy/pytorch_lite/blob/4d4ec5b397d676101c2544555fc6a2421f5b3b09/example/assets/labels/labels_objectDetection_Coco.txt)
    - models
        - bird_model.pt (convert [model20240824.pth](https://github.com/sun-jiao/MetaFGNet/releases) using [export_model.py](https://github.com/sun-jiao/bio_image_downloader/blob/3154767593f591c3517aabd79bae3a83d057217c/export_model.py))
        - yolo11n.pt (`yolo mode=export model=yolo11n.pt format=torchscript optimize`)
