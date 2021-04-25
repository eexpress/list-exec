//----------------------------------------------------------
//devhelp里面的 Namespace 使用 using; Package 使用 --pkg。
//! valac --pkg gtk+-3.0  --pkg posix "%f"
//----------------------------------------------------------

using Gtk;

int main(string[] args)
{
	Environment.set_current_dir(Path.get_dirname(args[0]));
    Gtk.init (ref args);
    var window = new Gtk.Window ();

    window.title = "通用侧栏";
    window.set_position (Gtk.WindowPosition.CENTER);
    window.destroy.connect (Gtk.main_quit);

	var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
	box.margin = 5;
	box.set_spacing(5);
//-----------------------------------------
	List[] lst = new List[5];	// 最多读取5个栏目。
	KeyFile file = new KeyFile ();
	int windex=1; string shellcmd;
	string[] list; string cmd; string title; bool show_search; string check;
	string ls_stdout; string ls_stderr; int ls_status;
//-----------------------------------------
	try{
		file.load_from_file((args[1]!=null)?args[1]:"conf.ini", KeyFileFlags.NONE);
		while(true){
			title = file.get_string("Key",windex.to_string());
//			print(title+"==========\n");
//			if(title==null){continue;}	// 判断失效，被 catch 中断了。除非每句get_string都单独try。
			windex++; if(windex>5){break;}	// 最多读取5个栏目。
//-----------------------------------------
//			shellcmd = "bash -c \""+file.get_string(title,"List").escape("0x7F-0xFF")+"\"";
			shellcmd = "bash -c \""+file.get_string(title,"List").replace("\"","\\\"")+"\"";
//			print("shellcmd: %s\n", shellcmd);
			Process.spawn_command_line_sync (shellcmd,
			out ls_stdout, out ls_stderr, out ls_status);
			if(ls_status!=0){ list = ls_stderr.split("\n"); }
			else{ list = ls_stdout.split("\n"); }
//-----------------------------------------
			check="x";		// 增加catch后，Check段可省略。
		try{
			shellcmd = "bash -c \""+file.get_string(title,"Check").replace("\"","\\\"")+"\"";
			Process.spawn_command_line_sync (shellcmd,
			out ls_stdout, out ls_stderr, out ls_status);
			if(ls_status!=0){ print(ls_stderr); }
			else{ check = ls_stdout.chomp(); }
		} catch(Error e){ print ("catch => %s\n", e.message); }
//-----------------------------------------
			cmd = file.get_string(title,"Exec");
			show_search = false;	// 缺省无搜索
		try{
			show_search = file.get_boolean(title,"Search");
		} catch(Error e){ print ("catch => %s\n", e.message); }
			lst[windex] = new List();
			box.pack_start (lst[windex].show(list, cmd, title, show_search, check), true, true, 0);
		}
	} catch(Error e){ print ("catch => %s\n", e.message); }
//-----------------------------------------
    window.add(box);
    int wheight = 300+(windex-1)*150;
    if(wheight<600){wheight=600;}
    if(wheight>900){wheight=900;}
    window.set_default_size(500, wheight);
    window.move(0,0);
//    Gdk.Rectangle r = Gdk.Display.get_primary_monitor.geometry;
//    Gdk.Rectangle r = Gdk.Display.get_monitor_at_window(window).geometry;
//    Gdk.Rectangle r = (Gdk.Rectangle)Gdk.Monitor.get_geometry();
//    print("---------"+r.height.to_string()+"-------------\n");
    window.show_all();
//    check();
    Gtk.main ();
    return 0;
}
//----------------------------------------------------------
//void check(){
//	SettingsSchemaSource sss = GLib.SettingsSchemaSource.get_default ();
//	SettingsSchema schema = sss.lookup ("org.gnome.system.proxy", true);	// bool recursive
//	if (schema == null) {print ("ID not found."); return;}

//	if(schema.has_key ("mode")){
//		SettingsSchemaKey ssk = schema.get_key ("mode");
//		Variant v = ssk.get_range();
//		size_t length = 0;
//		print("name: %s\n", ssk.get_name());	//mode
//		print ("range: %s, %s\n", v.get_string (out length), length.to_string());
////		print ("'%s', %"+size_t.FORMAT+"\n", v.get_string (out length), length);
//	}else{ print("no key found: mode\n"); return;}

//	GLib.Settings settings = new GLib.Settings.full (schema, null, null);
//	string greeting = settings.get_string ("mode");
//	print("current mode: %s\n", greeting);
//}

//	var ss = new GLib.Settings ("org.gnome.system.proxy");
//	string sm = ss.get_string ("mode");
//----------------------------------------------------------
class List {
	string[] mylist; string mycmd;
	public Gtk.Widget show(string[] list, string cmd, string title, bool show_search, string check){
		mylist = list; mycmd = cmd;
		var l = new ListExec(list, check);
		l.row_activated.connect((row)=>{
			string[] a = mylist[row.get_index()].split("#", 2);
			Posix.system("%s \"%s\" &".printf(mycmd, a[0]));	//包裹文件参数。后台执行。
		});
		var s = new Gtk.ScrolledWindow(null, null);
		var b = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		if(title!=""){
			var t = new Gtk.Label("⭕ "+title);
			t.xalign = (float)0;
			t.margin = 5;
			b.pack_start (t, false, true, 0);
		}
		if(show_search){
			var e = new Gtk.SearchEntry();
			l.set_filter_func((row)=>{
				if(e.text in mylist[row.get_index()]){return true;}
				return false;
			});
			e.search_changed.connect(()=>{l.invalidate_filter();});
			b.pack_start (e, false, true, 0);
		}
		s.add(l);
		b.pack_start (s, true, true, 0);
		return b;
	}
}
//----------------------------------------------------------
class ListExec : Gtk.ListBox {	// 纯显示内容。不做数据处理
	const string[] color = {"#3465a4", "#ce5c00", "#73d216", "#f57900"};	// 循环的颜色表
	HashTable<string, int> hash = new HashTable<string, int> (str_hash, str_equal);

// 构造函数，参数：list为“显示文字#标签”
	public ListExec(string[] list, string check){
//		this.set_selection_mode(Gtk.SelectionMode.SINGLE);
		int maxlen = 1;
		string[] a;
		string flag;
		for(int i = 0; i < list.length; i++){	// 计算标签最大长度，并补充缺少的flag。
			if(list[i].chomp()==""){continue;}
			if(list[i].contains("#")){
				a = list[i].split("#", 2);
				if(maxlen<a[1].length){maxlen = a[1].length;}
			}else{			// 没有#标签的，使用扩展名当标签
				flag = " ";
				a = list[i].split(".", -1);
				if(a.length>=2){ flag = a[a.length-1]; }
				if(flag==null){flag = " ";}
				if(maxlen<flag.length){maxlen = flag.length;}
				list[i] = list[i]+"#"+flag;
			}
		}
//-----------------------------
		int cindex = 0;	// 颜色索引，建立颜色散列表
		int ii=0;	// 为了高亮。ListBox没有length属性，不能获取最后一个row。
		foreach (string s in list){
			if(s.chomp()==""){continue;}
			a = s.split("#", 2);
			flag = a[1];
			string name = a[0].substring(a[0].last_index_of("/")+1);	//显示时，去掉路径
// 处理彩色的标签
			string fill = string.nfill(maxlen-flag.length,' ');	// 前导填充空格
			if(! hash.contains(flag)){	// 增加颜色索引
				hash.insert(flag, cindex); cindex++; cindex%=color.length;
			}
// 添加Lable
			var lbl = new Gtk.Label("");
			lbl.xalign = (float)0;
			lbl.set_markup(fill+"<span background=\""+color[hash.get(flag)]+
			"\"	foreground=\"#ffffff\"><b> "+flag+" </b></span>  "+name+"");
			this.insert(lbl, -1);
			if(name==check){
				this.select_row(get_row_at_index(ii));
			}
			ii++;
		}
	}
}
//----------------------------------------------------------
//----------------------------------------------------------

