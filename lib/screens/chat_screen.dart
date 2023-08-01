import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';

//firebase authentication
import 'package:firebase_auth/firebase_auth.dart';

//welcome screen
import './welcome_screen.dart';

class ChatScreen extends StatefulWidget {
  static const String id = 'chatScreen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final _auth = FirebaseAuth.instance;
  final _fireStore = FirebaseFirestore.instance;

  final textController = TextEditingController();

  late String message;
  late String currentUserEmail;

  //Color _messageContainerColor = Colors.grey.shade200;

  @override
  void initState() {
    super.initState();
    currentUserEmail = getCurrentUser();
  }

  dynamic getCurrentUser(){
    if(_auth.currentUser != null){
      return _auth.currentUser?.email;
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async{
                //Implement logout functionality
                await _auth.signOut();
                //context.mounted solves the 'asynchronous gap issue'
                if(_auth.currentUser == null && context.mounted ){
                  Navigator.pushNamed(context,WelcomeScreen.id);
                }
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/back2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(fireStore: _fireStore,currentUser:currentUserEmail),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textController,
                      onChanged: (value) {
                        //Do something with the user input.
                        setState((){
                          message = value;
                        });
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(

                    onPressed: () async{
                      //Implement send functionality.
                      textController.clear();
                      await _fireStore.collection('messages').add({'text':message,'sender':currentUserEmail,"createdAt":Timestamp.now()}).then((DocumentReference doc){
                        print('new message added to firestore database,document id:${doc.id}');
                      });
                    },
                    child: const Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({
    super.key,
    required FirebaseFirestore fireStore,
    required this.currentUser
  }) : _fireStore = fireStore;

  final FirebaseFirestore _fireStore;
  final currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').orderBy('createdAt',descending: true).snapshots(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return const Center(child: CircularProgressIndicator(backgroundColor: Colors.green,));
        }

        final messages = snapshot.data!.docs;

        List<MessageBubble> messageBubbles = [];

        for (var message in messages){
          final messageText = message['text'];
          final messageSender = message['sender'];
          final messageBubble = MessageBubble(text: messageText, sender: messageSender,isMe: currentUser == messageSender,);

          messageBubbles.add(messageBubble);
        }


        return Expanded(
          child: ListView(

            reverse: true,
            children: messageBubbles,
          ),
        );

      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.sender,
    required this.isMe
  });

  final String text;
  final String sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15,horizontal: 10),
      child: Column(
        crossAxisAlignment: isMe?CrossAxisAlignment.end:CrossAxisAlignment.start,
        children: [
          Text(sender,style: const TextStyle(fontSize: 10,color: Colors.white),),
          Material(
              elevation: 15,
              borderRadius:BorderRadiusDirectional.only(topStart: Radius.circular(isMe?20:0),bottomEnd:Radius.circular(20),bottomStart: Radius.circular(20),topEnd: Radius.circular(isMe?0:20) ),
              color: isMe?Colors.blue.shade400:Colors.white,
              child:Padding(
                padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 15),
                child: Text(text,style: isMe?TextStyle(color: Colors.white):TextStyle(color: Colors.grey.shade700),),
              )
          ),
        ],
      ),
    );
  }
}