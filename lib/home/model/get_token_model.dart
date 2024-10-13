class GetTokenModel {
  String? accessToken;
  int? code;
  String? message;

  GetTokenModel({this.accessToken, this.code, this.message});

  GetTokenModel.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    code = json['code'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['access_token'] = accessToken;
    data['code'] = code;
    data['message'] = message;
    return data;
  }
}
