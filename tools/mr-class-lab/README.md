# MR Class Lab

**[Start here: installation, Unity editing, controls, LAN companion and recorded-camera debugging](../../docs/mr-class-lab/README.md).**

One editable Unity / Quest application: registered-book guidance, physical tutorial, captions, a wiped 3D portal, actual cross-device scene synchronization and a skinned GLB avatar with animation. Camera/marker, recorded-camera and manual-placement inputs are explicitly separate.

```sh
python3 prepare.py
# Open unity/ in Unity 6000.4.5f1; Tools → MR Class → Create desktop preview scene → Play
python3 companion/server.py
python3 -m unittest discover -s companion -p 'test_*.py'
node companion/test-ui.cjs
```

The prepared-project ZIP contains `unity/` (open this exact directory in Unity Hub), the companion, the shared engine sources/binaries and their hashes. It needs no private assets or API keys. A full source checkout can rebuild the native tracker with `bash build-native.sh`; the prepared ZIP validates its included shared sources when the original repository tree is absent.

`unity/Assets/MRClass/` separates Core, Inputs, Mechanisms, Resources and Editor verification/build tools. [`THIRD-PARTY.md`](THIRD-PARTY.md) records the permitted sample avatar, glTF importer and engine dependencies. Private recordings and room data are never included.
