import 'package:kdbx/src/kdbx_entry.dart';
import 'package:kdbx/src/kdbx_file.dart';
import 'package:kdbx/src/kdbx_group.dart';
import 'package:kdbx/src/kdbx_object.dart';
import 'package:meta/meta.dart';

/// Helper object for accessing and modifing data inside
/// a kdbx file.
extension KdbxDao on KdbxFile {
  KdbxGroup createGroup({
    @required KdbxGroup parent,
    @required String name,
  }) {
    assert(parent != null, name != null);
    final newGroup = KdbxGroup.create(ctx: ctx, parent: parent, name: name);
    parent.addGroup(newGroup);
    return newGroup;
  }

  KdbxGroup findGroupByUuid(KdbxUuid uuid) =>
      body.rootGroup.getAllGroups().firstWhere((group) => group.uuid == uuid,
          orElse: () =>
              throw StateError('Unable to find group with uuid $uuid'));

  void deleteGroup(KdbxGroup group) {
    if (group.parent.name.get() == 'Trash') {
      group.parent.internalRemoveGroup(group);
    } else {
      move(group, getRecycleBinOrCreate());
    }
  }

  void deleteEntry(KdbxEntry entry, {bool forceDelete = false}) {
    if (entry.parent.name.get() == 'Trash' || forceDelete) {
      entry.parent.internalRemoveEntry(entry);
    } else {
      move(entry, getRecycleBinOrCreate());
    }
  }

  void move(KdbxObject kdbxObject, KdbxGroup toGroup) {
    assert(toGroup != null);
    kdbxObject.times.locationChanged.setToNow();
    if (kdbxObject is KdbxGroup) {
      kdbxObject.parent.internalRemoveGroup(kdbxObject);
      kdbxObject.internalChangeParent(toGroup);
      toGroup.addGroup(kdbxObject);
    } else if (kdbxObject is KdbxEntry) {
      kdbxObject.parent.internalRemoveEntry(kdbxObject);
      kdbxObject.internalChangeParent(toGroup);
      toGroup.addEntry(kdbxObject);
    }
  }
}
