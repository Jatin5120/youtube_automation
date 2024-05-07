import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend/data/data.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:http/http.dart' show Client, Response, MultipartRequest, MultipartFile;

/// API WRAPPER to call all the IsmLiveApis and handle the status codes
class ApiWrapper {
  const ApiWrapper(this.client);

  final Client client;

  /// Method to make all the requests inside the app like GET, POST, PUT, Delete
  Future<ResponseModel> makeRequest(
    String api, {
    String? baseUrl,
    required RequestType type,
    Map<String, String>? headers,
    dynamic payload,
    String field = '',
    String filePath = '',
    bool showLoader = false,
    bool showDialog = true,
    bool shouldEncodePayload = true,
    String? message,
  }) async {
    assert(
      type != RequestType.upload || (type == RequestType.upload && payload is! Map<String, String> && field.isNotEmpty && filePath.isNotEmpty),
      'if type is passed as [RequestType.upload] then payload must be of type Map<String, String> and field & filePath must not be empty',
    );
    assert(
      type != RequestType.get || (type == RequestType.get && payload == null),
      'if type is passed as [RequestType.get] then payload must not be passed',
    );

    /// To see whether the network is available or not
    var url = (baseUrl ?? Endpoints.baseUrl) + api;

    final uri = Uri.parse(url);

    AppLog.info('[Request] - ${type.name.toUpperCase()} - $uri\n$payload');

    if (showLoader) Utility.showLoader(message);
    try {
      // Handles API call
      var start = DateTime.now();
      var response = await _handleRequest(
        uri,
        type: type,
        headers: headers,
        payload: shouldEncodePayload ? jsonEncode(payload) : payload,
        field: field,
        filePath: filePath,
      );

      // Handles response based on status code
      var res = await _processResponse(
        response,
        showDialog: showDialog,
        startTime: start,
      );
      if (showLoader) {
        Utility.closeLoader();
      }
      if (res.statusCode != 406) {
        return res;
      }
      return makeRequest(
        api,
        baseUrl: baseUrl,
        type: type,
        headers: headers,
        payload: payload,
        field: field,
        filePath: filePath,
        showDialog: showDialog,
        showLoader: showLoader,
        shouldEncodePayload: shouldEncodePayload,
      );
    } on TimeoutException catch (e, st) {
      AppLog.error('TimeOutException - $e', st);
      if (showLoader) {
        Utility.closeLoader();
      }
      await Future.delayed(const Duration(milliseconds: 100));
      var res = ResponseModel.message(AppStrings.timeoutError);
      if (showDialog) {
        await Utility.showInfoDialog(
          res,
          title: 'Timeout Error',
          onRetry: () => makeRequest(
            api,
            baseUrl: baseUrl,
            type: type,
            headers: headers,
            payload: payload,
            field: field,
            filePath: filePath,
            showDialog: showDialog,
            showLoader: showLoader,
            shouldEncodePayload: shouldEncodePayload,
          ),
        );
      }
      return res;
    } on SocketException catch (e, st) {
      AppLog.info(e.runtimeType);
      AppLog.error(e, st);
      if (showLoader) {
        Utility.closeLoader();
      }
      await Future.delayed(const Duration(milliseconds: 100));
      var res = ResponseModel.message(AppStrings.socketProblem);

      if (showDialog) {
        await Utility.showInfoDialog(
          res,
          title: 'Network Error',
        );
      }
      return res;
    } on ArgumentError catch (e, st) {
      AppLog.info(e.runtimeType);
      AppLog.error(e, st);
      if (showLoader) {
        Utility.closeLoader();
      }
      await Future.delayed(const Duration(milliseconds: 100));
      var res = ResponseModel.message(AppStrings.somethingWentWrong);

      if (showDialog) {
        await Utility.showInfoDialog(
          res,
          title: 'Argument Error',
        );
      }
      return res;
    } catch (e, st) {
      AppLog.info(e.runtimeType);
      AppLog.error(e, st);
      if (showLoader) {
        Utility.closeLoader();
      }
      await Future.delayed(const Duration(milliseconds: 100));
      var res = ResponseModel.message('${AppStrings.somethingWentWrong}; $e');

      if (showDialog) {
        await Utility.showInfoDialog(res);
      }
      return res;
    }
  }

  Future<Response> _handleRequest(
    Uri api, {
    required RequestType type,
    Map<String, String>? headers,
    required String field,
    required String filePath,
    dynamic payload,
  }) async {
    switch (type) {
      case RequestType.get:
        return _get(api, headers: headers);
      case RequestType.post:
        return _post(api, payload: payload, headers: headers);
      case RequestType.put:
        return _put(api, payload: payload, headers: headers);
      case RequestType.patch:
        return _patch(api, payload: payload, headers: headers);
      case RequestType.delete:
        return _delete(api, payload: payload, headers: headers);
      case RequestType.upload:
        return _upload(
          api,
          payload: payload,
          headers: headers,
          field: field,
          filePath: filePath,
        );
    }
  }

  Future<Response> _get(
    Uri api, {
    Map<String, String>? headers,
  }) async =>
      await client
          .get(
            api,
            headers: headers,
          )
          .timeout(AppConstants.timeOutDuration);

  Future<Response> _post(
    Uri api, {
    required payload,
    Map<String, String>? headers,
  }) async =>
      await client
          .post(
            api,
            body: payload,
            headers: headers,
          )
          .timeout(AppConstants.timeOutDuration);

  Future<Response> _put(
    Uri api, {
    required dynamic payload,
    Map<String, String>? headers,
  }) async =>
      await client
          .put(
            api,
            body: payload,
            headers: headers,
          )
          .timeout(AppConstants.timeOutDuration);

  Future<Response> _patch(
    Uri api, {
    required dynamic payload,
    Map<String, String>? headers,
  }) async =>
      await client
          .patch(
            api,
            body: payload,
            headers: headers,
          )
          .timeout(AppConstants.timeOutDuration);

  Future<Response> _delete(
    Uri api, {
    required dynamic payload,
    Map<String, String>? headers,
  }) async =>
      await client
          .delete(
            api,
            body: payload,
            headers: headers,
          )
          .timeout(AppConstants.timeOutDuration);

  /// Method to make all the requests inside the app like GET, POST, PUT, Delete
  Future<Response> _upload(
    Uri api, {
    required Map<String, String> payload,
    Map<String, String>? headers,
    required String field,
    required String filePath,
  }) async {
    var request = MultipartRequest(
      'POST',
      api,
    )
      ..headers.addAll(headers ?? {})
      ..fields.addAll(payload)
      ..files.add(
        await MultipartFile.fromPath(field, filePath),
      );

    var response = await request.send();

    return await Response.fromStream(response);
  }

  /// Method to return the API response based upon the status code of the server
  Future<ResponseModel> _processResponse(
    Response response, {
    required bool showDialog,
    required DateTime startTime,
  }) async {
    var diff = DateTime.now().difference(startTime).inMilliseconds / 1000;
    AppLog('[Response] - ${diff}s ${response.statusCode} ${response.request?.url}\n${response.body}');

    switch (response.statusCode) {
      case 200:
      case 201:
      case 202:
      case 203:
      case 204:
      case 205:
      case 208:
        return ResponseModel(
          data: utf8.decode(response.bodyBytes),
          hasError: false,
          statusCode: response.statusCode,
        );
      case 400:
      case 401:
      case 404:
      case 406:
      case 409:
      case 410:
      case 412:
      case 413:
      case 415:
      case 416:
      case 429:
      case 522:
        if (response.statusCode == 401) {
          // UnAuthorized
          // Logic to clear the data and send user to login view
          // ex: Get.find<ProfileController>().clearData();
          //     RouteManagement.goToSignIn();
        } else if (response.statusCode == 406) {
          // Token expired
          // Logic to refresh the token the API will be called again automatically from the makeRequest function
          // ex: await Get.find<AuthController>().refreshToken();
        }
        var hasError = true;
        var res = ResponseModel(
          data: utf8.decode(response.bodyBytes),
          hasError: hasError,
          statusCode: response.statusCode,
        );
        if (![401, 406, 410].contains(response.statusCode) && showDialog) {
          await Utility.showInfoDialog(res);
        }
        return res;
      case 500:
        var res = ResponseModel.message(
          'Server error',
          statusCode: response.statusCode,
        );
        if (showDialog) {
          await Utility.showInfoDialog(res);
        }
        return res;

      default:
        return ResponseModel(
          data: utf8.decode(response.bodyBytes),
          hasError: true,
          statusCode: response.statusCode,
        );
    }
  }
}
