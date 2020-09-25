import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:finale/components/acrcloud_dialog_component.dart';
import 'package:finale/env.dart';
import 'package:finale/lastfm.dart';
import 'package:finale/types/generic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrcloud/flutter_acrcloud.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ScrobbleView extends StatefulWidget {
  final FullTrack track;
  final bool isModal;

  ScrobbleView({Key key, this.track, this.isModal = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ScrobbleViewState();
}

class _ScrobbleViewState extends State<ScrobbleView> {
  final _trackController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();

  var _useCustomTimestamp = false;
  DateTime _customTimestamp;

  @override
  void initState() {
    super.initState();
    _trackController.text = widget.track?.name;
    _artistController.text = widget.track?.artist?.name;
    _albumController.text = widget.track?.album?.name;

    if (!widget.isModal) {
      ACRCloud.setUp(ACRCloudConfig(Env.acrCloud.accessKey,
          Env.acrCloud.accessSecret, Env.acrCloud.host));
    }
  }

  Future<void> _scrobble(BuildContext context) async {
    final response = await Lastfm.scrobble([
      BasicConcreteTrack(
          _trackController.text, _artistController.text, _albumController.text)
    ], [
      _useCustomTimestamp ? _customTimestamp : DateTime.now()
    ]);

    if (widget.isModal) {
      Navigator.pop(context, response.ignored == 0);
    } else if (response.ignored == 0) {
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text('Scrobbled successfully!')));
      _trackController.text = '';
      _artistController.text = '';
      _albumController.text = '';
    } else {
      Scaffold.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while scrobbling')));
    }
  }

  // This widget is a circle whose size depends on the volume that the
  // microphone picks up. Unfortunately, it's too laggy and the size doesn't
  // change that much unless you make a noise very close to the microphone.
  // ignore: unused_element
  Widget _buildAudioIndicator(BuildContext context, ACRCloudSession session) {
    return StreamBuilder(
      stream: session.volume,
      initialData: 0.0,
      builder: (context, snapshot) => Container(
          height: 50,
          child: Center(
              child: ClipOval(
                  child: SizedBox(
                      width: 100 * snapshot.data + 10,
                      height: 100 * snapshot.data + 10,
                      child: Container(color: Colors.red))))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Scrobble'),
          actions: [
            Builder(
                builder: (context) => IconButton(
                    icon: Icon(Icons.add), onPressed: () => _scrobble(context)))
          ],
        ),
        body: Form(
            child: Container(
                margin: EdgeInsets.all(10),
                child: Column(
                  children: [
                    if (!widget.isModal)
                      Builder(
                          builder: (context) => OutlineButton(
                              padding: EdgeInsets.zero,
                              borderSide: BorderSide(color: Colors.red),
                              child: ListTile(
                                contentPadding: EdgeInsets.only(left: 12),
                                title: Text('Tap to recognize'),
                                trailing: FlatButton(
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Powered by ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption),
                                          Image.asset(
                                              'assets/images/acrcloud.png',
                                              height: 20)
                                        ]),
                                    onPressed: () {
                                      launch('https://acrcloud.com');
                                    }),
                              ),
                              onPressed: () async {
                                final result =
                                    await showDialog<ACRCloudDialogResult>(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) =>
                                            ACRCloudDialogComponent());

                                if (result.wasCancelled) return;

                                if (result.track != null) {
                                  setState(() {
                                    _trackController.text = result.track.title;
                                    _albumController.text =
                                        result.track.album?.name;
                                    _artistController.text =
                                        result.track.artists?.first?.name;
                                  });
                                } else {
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                      content:
                                          Text('Could not recognize song')));
                                }
                              })),
                    TextFormField(
                      controller: _trackController,
                      decoration: InputDecoration(labelText: 'Song'),
                    ),
                    TextFormField(
                      controller: _artistController,
                      decoration: InputDecoration(labelText: 'Artist'),
                    ),
                    TextFormField(
                      controller: _albumController,
                      decoration: InputDecoration(labelText: 'Album'),
                    ),
                    SwitchListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.red,
                      title: Text('Custom timestamp'),
                      value: _useCustomTimestamp,
                      onChanged: (value) {
                        setState(() {
                          _useCustomTimestamp = value;

                          if (_useCustomTimestamp) {
                            _customTimestamp = DateTime.now();
                          }
                        });
                      },
                    ),
                    Visibility(
                      visible: _useCustomTimestamp,
                      child: DateTimeField(
                          decoration: InputDecoration(labelText: 'Timestamp'),
                          resetIcon: null,
                          format: DateFormat('yyyy-MM-dd HH:mm:ss'),
                          initialValue: _customTimestamp,
                          onShowPicker: (context, currentValue) async {
                            final date = await showDatePicker(
                                context: context,
                                initialDate: currentValue ?? DateTime.now(),
                                firstDate:
                                    DateTime.now().subtract(Duration(days: 14)),
                                lastDate:
                                    DateTime.now().add(Duration(days: 1)));

                            if (date != null) {
                              final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                      currentValue ?? DateTime.now()));

                              return DateTimeField.combine(date, time);
                            }

                            return currentValue;
                          },
                          onChanged: (datetime) {
                            setState(() {
                              _customTimestamp = datetime;
                            });
                          }),
                    ),
                  ],
                ))));
  }

  @override
  void dispose() {
    super.dispose();
    _trackController.dispose();
    _artistController.dispose();
    _albumController.dispose();
  }
}
