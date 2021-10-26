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
        primarySwatch: Colors.teal,
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
                         FlatButton(
                           onPressed: (){
                             Navigator.pop(context);
                           },
                           child: Text("Cancel"),
                         )
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


          child : Padding(
            padding: EdgeInsets.all(5),
            child:
          Card(
            color: Colors.white70,
            elevation: 10.0,
            margin: EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(temp[i]["_name"],
                style: TextStyle(
                 fontSize: 20,color: Colors.black54
                ),),
                Text(temp[i]["_number"],
                style: TextStyle(
                 fontSize: 15,
                 color: Colors.black54
                ),),
                Padding(padding:EdgeInsets.all(5) ,),  
              ],
            ) ,
          ),),
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
        Padding(padding: EdgeInsets.all(8),),
        TextFormField(
          keyboardType:  TextInputType.text,
          controller: name,
          autofocus: false,
          decoration: InputDecoration(
            hintText: "Enter Name",
            contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20)
            ),
          ),
        ),
         Padding(padding: EdgeInsets.all(4),),
        Container(
         
            decoration: BoxDecoration(
              //color: Colors.green[200],
              border: Border.all(width: 1,color: Colors.grey),    
              borderRadius: BorderRadius.all(Radius.circular(20)),         
              ),
          child: Row(
            //mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 200,
              child:  
               TextFormField(
          keyboardType:  TextInputType.number,
          controller: textc1,
          autofocus: false,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Enter phone number",
            contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          ),
        ),
            ),
           FlatButton(
             onPressed: _isbuttonDisabled ? (){
               widget._scaffoldKey.currentState.showSnackBar(
                 SnackBar(content: Text("Contacts Still Loading......."),));
             } : _selectContact,
             child: Icon(Icons.contacts,color: Colors.black54,),
           ),
          ],
        ),
        ),
        Padding(padding: EdgeInsets.all(4),),
           TextFormField(
             keyboardType: TextInputType.multiline,
             minLines: 3,
             maxLines: null,
             controller: textc2,
             autofocus: false,
             decoration: InputDecoration(
               hintText: "Enter message",
               contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
               border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18)
               ),
             ),
           ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Material(
                color: Colors.teal[600],
                borderRadius: BorderRadius.circular(30),
                shadowColor: Colors.tealAccent.shade100,
                elevation: 10.0,
                child: MaterialButton(
                  minWidth: 200.0,
                  height: 42,
                  child: Text("Press to send",style: TextStyle(color: Colors.white,fontSize: 16),),
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
                 'access_id':{ACCESS_ID},
                 'access_key':{ACCESS_KEY}
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
                   widget._scaffoldKey.currentState.showSnackBar(
                     new SnackBar(content: Text("Message sent successfully to $phone"),));
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
              ),
            ),
           Padding(padding: EdgeInsets.all(5),),
           Align(
             alignment: Alignment.centerLeft,
             child:
           Text("Recent Contacts",
           style: TextStyle(
             fontSize: 20,
             color: Colors.black54
           ),)),
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
      //backgroundColor: Colors.green[50],
      appBar: AppBar(title: Text("Welcome! Vikash Yadav"),centerTitle: true,),
      body:Center(
        child:
      ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(left: 5.0,right: 5.0),
        scrollDirection: Axis.vertical,
        children: <Widget>[
                           column,
        ],
      ) ,) 
    );
    return scaffold;
  }
  
}
