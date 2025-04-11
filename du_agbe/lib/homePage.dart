import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/avatar.jpeg'),
                ),
                SizedBox(width: 5,),
                Text("Hello,")
              ],
            ),
            SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextField(
                decoration: InputDecoration(
                  hintText: 'Dites -nous ce que vous voulez ',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ),
                IconButton(
                  onPressed: (){},
                  icon: Icon(Icons.mic))
              ],
            )
          ],
        ),
      ),
    );
  }
}