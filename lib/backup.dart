import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DatabaseHelper.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var materialApp = MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Aws_app",
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
    );
    return materialApp;
  }
}

class HomePage extends StatefulWidget{
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return HomePageState(_scaffoldKey);
  }
}

class HomePageState extends State<HomePage>{
  
  HomePageState(this._scaffoldKey);

  final GlobalKey<ScaffoldState> _scaffoldKey;
  var textc1 = TextEditingController();
  var textc2 = TextEditingController();
  var name =  TextEditingController();
  bool _isloading = false;
  bool _isbuttonDisabled = true;
  List<Contact> _contact ;
  List<Map<String,dynamic>> contact_list;
  DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  Map<String,dynamic> recent = {};

  _insertData(Map<String,dynamic> map) {
    _databaseHelper.insert(map);
  }

  _getContactfromDatabase() async{
  List<Map<String,dynamic>> get_contact = await _databaseHelper.queryAll();
   setState((){
     contact_list= get_contact;
    _isloading = false; 
   });
  }

  _readContact() async {
    ContactsService.getContacts().then((onValue){
      setState(() {
         _contact = onValue.where((item)=>item.displayName!=null).toList();
         _isbuttonDisabled = false;
      });
     });
  }

  _selectContact() async{
       showDialog(
                     context: context,
                     builder:(context) =>AlertDialog(
                       title: Text("Select Contact"),
                       content: Container(child: 
                       ListView.builder(
                         itemCount: _contact.length,
                         itemBuilder: (BuildContext context, int  index){
                               return _buildListTile(_contact[index],_contact[index].phones.toList());
                         },
                       )
                       ),
                       actions: <Widget>[
                         
                       ],
                     )
                   );
     }               

     _buildListTile(Contact contact , List<Item> item){
              return GestureDetector(
                onTap: (){
                   name.text = contact.displayName;
                   textc1.text = item[0].value;
                   Navigator.pop(context);
                },
                child: ListTile(
                    leading: CircleAvatar(
                      child: 
                      Text(contact.displayName[0] + 
                      contact.displayName[1].toUpperCase(),
                      style: TextStyle(color: Colors.white),
                      ),
                      ),
                    title: Text(contact.displayName ?? ""),
                    subtitle: item.length>=1 && item[0]?.value !=null ? Text(item[0].value):Text(""),
              ),
              );
     }

  List<Widget> _getPreviousContactView(List<Map<String,dynamic>> temp){
    List<Widget> widget =[];
    if(temp.isEmpty ){
      widget.add(Text("No previous contact "));
    }
    else{
      for(int i=0;i<temp.length;i++){
           recent[temp[i]["_name"]] =temp[i]["_number"]; 
             var column = GestureDetector(
               onTap: (){
                 textc1.text= temp[i]["_number"];
                 name.text= temp[i]["_name"];
               },


          child : Card(
            margin: EdgeInsets.all(5),
            //decoration: BoxDecoration(
              // border: Border.all(width:2),
              // color: Colors.grey
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(temp[i]["_name"],
                style: TextStyle(
                 fontSize: 20
                ),),
                Text(temp[i]["_number"],
                style: TextStyle(
                 fontSize: 15
                ),),
                Padding(padding:EdgeInsets.all(5) ,),  
              ],
            ) ,
          ),
        );
        widget.add(column);
      }
    }
    return widget;
  }


@override
  void initState() {
    super.initState();
    PermissionHandler().requestPermissions([PermissionGroup.contacts]).then((granted){
      if(granted[PermissionGroup.contacts] == PermissionStatus.granted){
        _readContact();
         setState((){
    _isloading = true; 
      });
      }
      else{
        showDialog(
          context: context,
          builder: (context) =>AlertDialog(
            title: Text("Oops!"),
            content: Text('Looks like permission to read contact does not granted.'),
            actions: <Widget>[
              FlatButton(
              child: Text('Ok'),
              onPressed: (){
                Navigator.pop(context);
              },
              ),
            ],
          )
        );
      }
    });
     setState((){
    _isloading = true; 
   });
     _getContactfromDatabase();
  }

  @override
  Widget build(BuildContext context) {

    var column = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[

        TextField(
             controller: name,
             decoration: InputDecoration(
               hintText: "Enter Name",
             ),
           ),

        Container(
          child: Row(
            //mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 270,
              child:  TextField(
             controller: textc1,
             decoration: InputDecoration(
               hintText: "Enter phone number",
             ),
           ),
            ),
           FlatButton(
             onPressed: _isbuttonDisabled ? null : _selectContact,
             child: Icon(Icons.contact_phone),
           ),
          ],
        ),
        ),
           TextField(
             controller: textc2,
             decoration: InputDecoration(
               hintText: "Enter message"
             ),
           ),
           RaisedButton(
             child: Text("Send"),
             onPressed: () async{
               String ph = textc1.text;
               String phone;
               if(ph.substring(0,3)=='+91' ){
                     phone = ph;
               }else
               if(ph[0]=='0'){
                 phone = '+91'+ph.substring(1,ph.length);
               }
               else{
                 phone =  "+91" + ph;
               }
               var message = textc2.text;
               var map = {
                 'phone' : phone,
                 'message': message,
                 'access_id':"AKIAYSLDQVJHQXTZ7H73",
                 'access_key':"GRi6F7Efvpofg+El7Hioj+KrnTAFnn0l++V1qaJm"
               };
              var json_data = jsonEncode(map);
              var resp = await http.post("http://singham.pythonanywhere.com/send",
               headers: {"Content-Type" : "application/json"},
               body: json_data
                );
                var j = jsonDecode(resp.body);
              
                print(resp.body);
                textc1.text="";
                textc2.text="";
                if(j["response"]["ResponseMetadata"]["HTTPStatusCode"]==200){
                   widget._scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text("Message sent successfully to $phone"),));
                }
                else{
                  Scaffold.of(context).showSnackBar(new SnackBar(content: Text("Message sent Failed"),));
                }
                int flag = 0;
                if(recent !=null){
                 for(String num in recent.values){
                         if(phone.compareTo(num) == 0){
                           flag = 1;
                           break;
                         }
                 }
                }

                 if(recent == null || flag ==0){
                   Map<String,dynamic> dataToEnter ={
                    
                     "_name":name.text,
                     "_number":phone
                   };
                       _insertData(dataToEnter);
                       _getContactfromDatabase();

                 }
                 textc1.text = "";
                 textc2.text = "";
                 name.text = "";

             },
           ),
           Padding(padding: EdgeInsets.all(5),),
           Text("Recent Contacts",
           style: TextStyle(
             fontSize: 25
           ),),
           Padding(padding: EdgeInsets.all(5)),
           Container(),
           
           Container(
            height:300,
             child: !_isloading
            ? ListView(
             scrollDirection: Axis.vertical,
             children:_getPreviousContactView(contact_list)
           )
           : Center(child: CircularProgressIndicator(),),
           ),      
      ],
    );

    var scaffold = Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text("Send SMS"),),
      body:ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
                           column,
        ],
      )  
    );
    return scaffold;
  }
  
}