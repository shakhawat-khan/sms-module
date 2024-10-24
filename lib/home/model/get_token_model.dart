class GetTokenModel {
  Data? data;
  int? code;
  String? message;

  GetTokenModel({this.data, this.code, this.message});

  GetTokenModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    code = json['code'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['code'] = code;
    data['message'] = message;
    return data;
  }
}

class Data {
  String? clientSecret;

  Data({this.clientSecret});

  Data.fromJson(Map<String, dynamic> json) {
    clientSecret = json['client_secret'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['client_secret'] = clientSecret;
    return data;
  }
}
