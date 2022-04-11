// import 'package:photo_album_manager/album_model_entity.dart';

import 'package:contacts_service/contacts_service.dart';

import 'common.dart';

class LocalContact {
  static Future cleanContacts() async {
    var contacts = await ContactsService.getContacts();
    for (var item in contacts) {
      // print('${item.identifier}');
      await ContactsService.deleteContact(item);
    }
  }

  static Future<int> getContactsCount() async {
    return (await ContactsService.getContacts()).length;
  }

  static Future<List> getContacts() async {
    return (await ContactsService.getContacts())
        .map((a) => {
              "contactPerson": {
                "userDefined": [
                  {'key': 'identifier', 'value': '${a.identifier}'}
                ],
                "names": [
                  {
                    "familyName": a.familyName,
                    "givenName": a.givenName,
                    'middleName': a.middleName,
                    'displayName': a.displayName
                  }
                ],
                "phoneNumbers": a.phones
                    ?.map((b) => {"value": b.value, "type": b.label})
                    .toList(),
                "addresses": a.postalAddresses
                    ?.map((a1) => {
                          "type": a1.label,
                          "streetAddress": a1.street,
                          "extendedAddress": "",
                          "city": a1.city,
                          "region": a1.region,
                          "postalCode": a1.postcode,
                          "country": a1.country,
                        })
                    .toList(),
                "emailAddresses": a.emails
                    ?.map((a1) => {"value": a1.value, "displayName": a1.label})
                    .toList(),
              }
            })
        .toList();
  }

  static Future<int> writeContacts(List allcontact) async {
    int i = 0;
    for (var _contact in allcontact) {
      Contact contact = Contact();
      contact.identifier = _contact['resourceName'];
      contact.givenName = _contact['names']?[0]['displayName'];
      contact.displayName = _contact['names']?[0]['displayName'];
      contact.phones = [
        Item(
            label: _contact['phoneNumbers']?[0]['type'],
            value: _contact['phoneNumbers']?[0]['value'])
      ];

      // if (_contact['photos'] != null && _contact['photos'].length > 0) {
      //   // contact.avatar = ImageHelper.base64ToImage(_contact['avatar']);
      //   print(_contact['photos'][0]);
      // }
      i++;
      await ContactsService.addContact(contact);
    }
    return i;
  }

  static Future<int> writeContactsFromFile(List allcontact) async {
    int i = 0;
    for (var _contact in allcontact) {
      // print('${_contact}');
      Contact contact = Contact();
      contact.identifier = _contact['resourceName'];
      contact.givenName = _contact['displayName'];
      contact.displayName = _contact['displayName'];

      if (_contact['phones'] != null && _contact['phones'].length > 0) {
        contact.phones = [
          Item(
              label: _contact['phones']?[0]['label'],
              value: _contact['phones']?[0]['value'])
        ];
      }
      if (_contact['avatar'] != null) {
        contact.avatar = ImageHelper.base64ToImage(_contact['avatar']);
      }
      i++;
      await ContactsService.addContact(contact);
    }
    return i;
  }
}
