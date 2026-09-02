import 'package:flutter/material.dart';
import 'package:muserpol_pvt/components/headers.dart';
import 'package:muserpol_pvt/model/contacts_model.dart';
import 'package:muserpol_pvt/screens/contacts/card_contact.dart';
import 'package:muserpol_pvt/services/service_method.dart';
import 'package:muserpol_pvt/services/services.dart';

class ScreenContact extends StatefulWidget {
  const ScreenContact({super.key});

  @override
  State<ScreenContact> createState() => _ScreenContactState();
}

class _ScreenContactState extends State<ScreenContact> {
  ContactsModel? contact;

  @override
  void initState() {
    super.initState();
    getContacts();
  }

  Future<void> getContacts() async {
    var response = await serviceMethod(
      mounted,
      context,
      'get',
      null,
      serviceGetContacts(),
      false,
      false,
    );
    if (response != null) {
      setState(() => contact = contactsModelFromJson(response.body));
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: obtenemos el padding inferior real del dispositivo (gestos/home indicator)
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: SafeArea( // FIX: envolvemos en SafeArea para respetar notch/status bar/gestos
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: Column(
            children: [
              const HedersComponent(title: 'Contactos a nivel nacional'),
              contact != null
                  ? Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        // FIX: sumamos el bottomSafeArea + un margen extra
                        padding: EdgeInsets.only(bottom: 2 + bottomSafeArea),
                        child: Column(
                          children: List.generate(
                            contact!.data!.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CardContact(
                                city: contact!.data![index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const Expanded(
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          child: Image(
                            image: AssetImage('assets/images/load.gif'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}