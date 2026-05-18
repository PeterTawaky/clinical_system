class ApiConstants {
  // Notion API
  // static final notion = _NotionApi();
  // Google Books API
  static final scadaData = _ScadaDataApi();
}

//! Notion API implementation
// class _NotionApi {
//   final String baseUrl = 'https://api.notion.com/v1';
//   final keys = _NotionKeys();

//   final endpoints = _NotionEndpoints();
// }

// class _NotionEndpoints {
//   final String pages = '/pages';
//   final String databases = '/databases';
//   final String createPage = '/pages';
// }

// class _NotionKeys {
//   String status = 'status';
//   String code = 'code';
//   String message = 'message';
//   String source = 'source';
//   String author = 'author';
//   String title = 'title';
//   String name = 'name';
//   String urlToImage = 'urlToImage';
//   String q = 'q';
//   String apiKey = 'apiKey';
// }

class _ScadaDataApi {
  final String baseUrl = 'http://10.12.114.169:8000/'; //peter server
  final String weatherBaseUrl = 'http://api.weatherapi.com/v1/';
  final ScadaDataEndpoints endpoints = ScadaDataEndpoints();
  final keys = _ScadaDataKeys();
}

class ScadaDataEndpoints {
  final String chatbot = 'chatbot';
  final String historyAlarms = 'alarms/alarm_history/inverter';
  final String onlineAlarms = 'alarms/online_alarms/inverter';
  final String acknowledgeAlarm = 'alarms/acknowledge_alarm';
  final String history = 'history';
  final String activeTasks = 'maintenance_task/active';
  final String acknowledgeTask = 'maintenance_task/acknowledge';
  final String createTask = 'maintenance_task/create';
  final String databaseBackups = 'DB_handling/database_backups';
  final String createBackup = 'DB_handling/create_backup';
  final String restoreBackup = 'DB_handling/restore_backup';
  final String deleteBackup = 'DB_handling/delete_backup';
  // final String getEventsData = 'event/event_history';
  final String forecastWeather = 'forecast.json';
}

class _ScadaDataKeys {
  String id = 'tag_id';
  String startMinute = 'start_minute';
  String startHour = 'start_hour';
  String startDay = 'start_day';
  String startMonth = 'start_month';
  String endMinute = 'end_minute';
  String startYear = 'start_year';
  String endYear = 'end_year';
  String endHour = 'end_hour';

  String endDay = 'end_day';
  String endMonth = 'end_month';

  String apiKey = 'apiKey';
}
