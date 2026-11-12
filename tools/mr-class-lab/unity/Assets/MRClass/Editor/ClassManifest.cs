using System.IO;
using System.Xml;
using UnityEditor.Android;
namespace MRClass.Editor
{
// Runtime AddComponent camera adapters are not discoverable as serialized SDK components.
public sealed class ClassManifest : IPostGenerateGradleAndroidProject
{
    public int callbackOrder => 1000000; // After Meta's order-99999 manifest regeneration.
    const string Android = "http://schemas.android.com/apk/res/android";
    public void OnPostGenerateGradleAndroidProject(string path)
    {
        string file = Path.Combine(path, "src/main/AndroidManifest.xml");
        var xml = new XmlDocument();
        xml.Load(file);
        var root = xml.DocumentElement;
        Add(xml, root, "uses-permission", "horizonos.permission.HEADSET_CAMERA");
        Add(xml, root, "uses-permission", "android.permission.CAMERA");
        var feature = Add(xml, root, "uses-feature", "com.oculus.feature.PASSTHROUGH");
        feature.SetAttribute("required", Android, "true");
        xml.Save(file);
    }
    static XmlElement Add(XmlDocument xml, XmlElement root, string tag, string name)
    {
        foreach (XmlElement element in root.GetElementsByTagName(tag))
            if (element.GetAttribute("name", Android) == name)
                return element;
        var e = xml.CreateElement(tag);
        e.SetAttribute("name", Android, name);
        root.AppendChild(e);
        return e;
    }
}
}
