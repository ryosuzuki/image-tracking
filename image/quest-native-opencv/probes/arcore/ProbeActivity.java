package org.openclaw.questarcoreprobe;
import android.app.Activity;
import android.os.Bundle;
import android.os.Build;
import android.util.Log;
import android.widget.TextView;
import com.google.ar.core.ArCoreApk;
import java.io.FileOutputStream;
/** Read-only SDK availability probe. Never requests service installation or opens a camera. */
public class ProbeActivity extends Activity {
    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        TextView label=new TextView(this); label.setTextSize(22); label.setPadding(24,24,24,24);setContentView(label);
        try {
            ArCoreApk.Availability result=ArCoreApk.getInstance().checkAvailability(this);
            String text="ARCore SDK 1.53.0\nDevice: "+Build.MANUFACTURER+" "+Build.MODEL+"\nAvailability: "+result.name()+"\nSupported: "+result.isSupported()+"\nTransient: "+result.isTransient()+"\nNo service installation or camera access attempted.";
            label.setText(text);Log.i("QuestArCoreProbe",text);
            try(FileOutputStream out=openFileOutput("result.txt",MODE_PRIVATE)){out.write(text.getBytes("UTF-8"));}
        }catch(Throwable error){String text=error.toString();label.setText(text);Log.e("QuestArCoreProbe",text,error);}
    }
}
