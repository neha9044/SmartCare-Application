import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import 'package:smartcare_app/screens/patient/valut_service.dart';
import 'package:smartcare_app/screens/patient/valut_model.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<VaultFile> files = [];

  bool loading = true;
  bool processing = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future load() async {
    files = await VaultService.getVaultFiles();

    setState(() {
      loading = false;
    });
  }

  Future addFile() async {
    setState(() => processing = true);

    await VaultService.addFileToVault();

    await load();

    setState(() => processing = false);
  }

  Future viewFile(VaultFile file) async {
    final temp = await VaultService.decryptTempFile(file.fileId);

    if (temp != null) {
      await OpenFilex.open(temp.path);
    }
  }

  Future restoreFile(VaultFile file) async {
    setState(() => processing = true);

    await VaultService.restoreFile(file);

    await load();

    setState(() => processing = false);
  }

  Future deleteFile(VaultFile file) async {
    setState(() => processing = true);

    await VaultService.deleteFile(file);

    await load();

    setState(() => processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B0F),

      appBar: AppBar(
        title: const Text("Blackout Vault"),
        backgroundColor: const Color(0xFF050B0F),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addFile,
        label: const Text("Add File"),
        icon: const Icon(Icons.add),
      ),

      body: Stack(
        children: [
          loading
              ? const Center(child: CircularProgressIndicator())
              : files.isEmpty
              ? const Center(
                  child: Text(
                    "Vault is empty",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: files.length,

                  itemBuilder: (context, i) {
                    final file = files[i];

                    return Card(
                      margin: const EdgeInsets.all(12),

                      child: ListTile(
                        title: Text(file.originalName),

                        subtitle: const Text("Encrypted & Hidden"),

                        leading: const Icon(Icons.lock),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => viewFile(file),
                            ),

                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () => restoreFile(file),
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteFile(file),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          if (processing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
