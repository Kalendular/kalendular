import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:caldav/caldav.dart';
import 'package:caldav/src/types.dart' as types;

class AddCalendarPage extends StatelessWidget {

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title = 'Widget';

  /// Returns URL of user's principal
  Future<String> getCurrentUserPrincipal(CalDavClient client) async {
    var requestResponse = await client.getWebDavResponse(
        '',
        body: '<x0:propfind xmlns:x0="DAV:"><x0:prop><x0:current-user-principal/></x0:prop></x0:propfind>'
    );

    var prop = client.findProperty(requestResponse, new WebDavProp('current-user-principal'));
    var hrefObj = (prop.value as List<WebDavProp>).firstWhere(types.isHrefProp);
    return hrefObj.value.toString();
  }

  /// Returns path to user's home calendar
  Future<String> getUserHomeCalendar(CalDavClient client) async {
    String userPrincipal = await getCurrentUserPrincipal(client);
    var requestResponse = await client.getWebDavResponse(
        userPrincipal,
        body: '<x0:propfind xmlns:x0="DAV:"><x0:prop><x1:calendar-home-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/></x0:prop></x0:propfind>'
    );
    var prop = client.findProperty(requestResponse, new WebDavProp('calendar-home-set', namespace: 'urn:ietf:params:xml:ns:caldav'));
    var hrefObj = (prop.value as List<WebDavProp>).firstWhere(types.isHrefProp);
    return hrefObj.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(this.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'AddCalendar page',
            ),
            RaisedButton(
              child: Text('Connect'),
              onPressed: () async {
                CalDavClient client = CalDavClient(
                    DotEnv().env['CALDAV_HOST'],
                    DotEnv().env['CALDAV_USER'],
                    DotEnv().env['CALDAV_PASSWORD'],
                    DotEnv().env['CALDAV_PATH'], // no slash at the end
                    protocol: DotEnv().env['CALDAV_PROTOCOL']
                );

                String userHome = await getUserHomeCalendar(client);
                var calendars = await client.getCalendars(userHome);
                calendars.forEach((calendar) {
                  developer.log(calendar.toString());
                });

                var personalCalendar = calendars.firstWhere((cal) => cal.displayName == 'Persönlich');
                client.createCalendarEvent(personalCalendar.path);
              },
            ),
            RaisedButton(
              child: Text('Go back'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}