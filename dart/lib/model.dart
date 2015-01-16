library model;

import 'package:angular/angular.dart' as ng;
import 'dart:mirrors' as mirrors;
import 'dart:async' as async;
import 'dart:math' as math;

var _attrData = {};

class Attr {
  final name;
  const Attr(this.name);
}

class Model {
  var _loadCheckId;
  var http;
  var url;
  var errorStatus;
  var errorData;
  var loadingLong;

  get _attrs {
    if (!_attrData.containsKey(this.runtimeType)) {
      var attrs = {};
      var mirror = mirrors.reflect(this).type;

      mirror.declarations.forEach((varSymbol, varMirror) {
        varMirror.metadata.forEach((metadata) {
          attrs[metadata.reflectee.name] = varSymbol;
        });
      });

      _attrData[this.runtimeType] = attrs;
    }
    return _attrData[this.runtimeType];
  }

  var _loading;
  set loading(val) {
    if (val) {
      var loadCheckId = new math.Random().nextInt(32000);
      this._loadCheckId = loadCheckId;
      this._loading = true;

      new async.Future.delayed(
        new Duration(milliseconds: 200), () {
          if (this._loadCheckId == loadCheckId) {
            this.loadingLong = true;
          }
        });
    }
    else {
      this._loadCheckId = null;
      this.loadingLong = false;
      this._loading = false;
    }
  }
  get loading {
    return this._loading;
  }

  Model(ng.Http this.http);

  fetch() {
    this.loading = true;

    return this.http.get(this.url).then((response) {
      this.loading = false;
      this.import(response.data);
      return response.data;
    }).catchError((err) {
      this.loading = false;
      this.errorStatus = err.status;
      this.errorData = err.data;
      throw err;
    });
  }

  parse(data) {
    return data;
  }

  import(responseData) {
    var attrs = this._attrs;
    var data = this.parse(responseData);
    var mirror = mirrors.reflect(this);

    data.forEach((key, value) {
      var symbol = attrs[key];
      if (symbol == null) {
        return;
      }

      mirror.setField(symbol, value);
    });
  }

  _send(method, fields) {
    var data = {};
    var attrs = this._attrs;
    var mirror = mirrors.reflect(this);

    this.loading = true;

    if (fields != null) {
      fields.forEach((name) {
        var symbol = attrs[name];
        data[name] = mirror.getField(symbol).reflectee;
      });
    }
    else {
      attrs.forEach((name, symbol) {
        data[name] = mirror.getField(symbol).reflectee;
      });
    }

    if (method == 'post') {
      method = this.http.post;
    }
    else if (method == 'put') {
      method = this.http.put;
    }
    else {
      throw new ArgumentError('Unkown method');
    }

    return method(this.url, data).then((response) {
      this.loading = false;
      this.import(response.data);
      return response.data;
    }).catchError((err) {
      this.loading = false;
      this.errorStatus = err.status;
      this.errorData = err.data;
      throw err;
    });
  }

  save([fields]) {
    return this._send('put', fields);
  }

  create([fields]) {
    return this._send('post', fields);
  }

  clear() {
    var attrs = this._attrs;
    var mirror = mirrors.reflect(this);

    attrs.values.forEach((symbol) {
      mirror.setField(symbol, null);
    });
  }
}
