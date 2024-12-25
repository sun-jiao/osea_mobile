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
  static const String locationSelection = 'selectLocation';
  static const String locationDisabled = 'locationDisabled';
  static const String locationPermissionDenied = 'locationPermissionDenied';
  static const String locationFilter = 'locationFilter';
  static const String locationFilterFix = 'locationFilterFix';
  static const String locationFilterAuto = 'locationFilterAuto';
  static const String locationFilterOff = 'locationFilterOff';
  static const String locationRetrieveFailed = 'locationRetrieveFailed';
  static const String locationFilterError = 'locationFilterError';

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
    locationSelection: 'Location Selection',
    locationDisabled: "Location services are disabled. Please enable the services",
    locationPermissionDenied: "Location permissions are permanently denied, we cannot request permissions",
    locationFilter: 'Distribution Filter',
    locationFilterFix: 'Fixed location (select on map)',
    locationFilterAuto: 'Auto update (based on device location)',
    locationFilterOff: 'Turn off location filter',
    locationRetrieveFailed: 'Failed in retrieving device location, distribution filter not applied.',
    locationFilterError: 'Distribution filter not applied due to unknown error.',
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
    locationSelection: '地点选择',
    locationDisabled: "定位服务未开启，请开启定位服务",
    locationPermissionDenied: "位置权限已被永久拒绝，无法请求位置权限",
    locationFilter: '分布区过滤',
    locationFilterFix: '固定地点（在地图上选择）',
    locationFilterAuto: '自动更新（根据手机定位）',
    locationFilterOff: '关闭分布区过滤',
    locationRetrieveFailed: '未能获取位置信息，分布区过滤未能生效。',
    locationFilterError: '发生未知错误，分布区过滤未能生效。',
  };
}

const Map<String, String> languageMap = {
  'en': 'English',
  'zh': '中文',
};