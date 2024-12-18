// ignore_for_file: constant_identifier_names

mixin AppLocale {
  static const String title = 'title';
  static const String imgNeeded = 'imgNeeded';
  static const String settings = 'settings';
  static const String uiLanguage = 'uiLanguage';
  static const String cnLanguage = 'cnLanguage';
  static const String nameDisplay = 'nameDisplay';
  static const String commonName = 'commonName';
  static const String scientificName = 'scientificName';
  static const String nameBoth = 'nameBoth';

  static const Map<String, dynamic> EN = {
    title: 'Bird ID',
    imgNeeded: 'Upload a bird image to recognize it',
    settings: 'Settings',
    uiLanguage: 'UI Language',
    cnLanguage: 'Common name Language',
    nameDisplay: 'Species name display',
    commonName: 'Common name',
    scientificName: 'Scientific name',
    nameBoth: 'Both',
  };
  static const Map<String, dynamic> ZH = {
    title: 'Bird ID',
    imgNeeded: '请上传图片以供识别',
    settings: '设置',
    uiLanguage: '界面语言',
    cnLanguage: '俗名语言',
    nameDisplay: '物种名称显示',
    commonName: '俗名',
    scientificName: '学名',
    nameBoth: '二者均显示',
  };
}

const Map<String, String> languageMap = {
  'en': 'English',
  'zh': '中文',
};