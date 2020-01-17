//----------------------------------------------------------
//devhelp里面的 Namespace 使用 using; Package 使用 --pkg。
//! valac --pkg gtk+-3.0  --pkg posix "%f"
// ./Gbar conf.ini
//----------------------------------------------------------

using Gtk;

int main(string[] args)
{
    Gtk.init (ref args);
    var window = new Gtk.Window ();

    window.title = "通用侧栏";
    window.set_position (Gtk.WindowPosition.CENTER);
    window.destroy.connect (Gtk.main_quit);

	var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
	box.margin = 5;
	box.set_spacing(5);
//-----------------------------------------
	List[] lst = new List[5];
	KeyFile file = new KeyFile ();
	int windex=1; string shellcmd;
	string[] list; string cmd; string title; bool show_search;
	string ls_stdout; string ls_stderr; int ls_status;
//-----------------------------------------
	try{
		file.load_from_file(args[1], KeyFileFlags.NONE);
		while(true){
			title = file.get_string("Key",windex.to_string());
//			if(title==null){continue;}	// 判断失效，被 catch 中断了。除非每句get_string都单独try。
			windex++; if(windex>5){break;}
			shellcmd = file.get_string(title,"List");
//-----------------------------------------
//			Process.spawn_command_line_sync ("sh -c \"%s\"".printf(shellcmd),
			Process.spawn_command_line_sync (shellcmd,
			out ls_stdout, out ls_stderr, out ls_status);
			if(ls_status!=0){ list = ls_stderr.split("\n"); }
			else{ list = ls_stdout.split("\n"); }
			cmd = file.get_string(title,"Exec");
			show_search = file.get_boolean(title,"Search");
			lst[windex] = new List();
			box.pack_start (lst[windex].show(list, cmd, title, show_search), true, true, 0);
		}
	} catch(Error e){ print ("catch => %s\n", e.message); }
//-----------------------------------------
    window.add(box);
    window.set_default_size(500, 300+(windex-1)*150);
    window.move(0,0);
//    Gdk.Rectangle r = Gdk.Display.get_primary_monitor.geometry;
//    Gdk.Rectangle r = Gdk.Display.get_monitor_at_window(window).geometry;
//    Gdk.Rectangle r = (Gdk.Rectangle)Gdk.Monitor.get_geometry();
//    print("---------"+r.height.to_string()+"-------------\n");
    window.show_all();
    Gtk.main ();
    return 0;
}
//----------------------------------------------------------
//----------------------------------------------------------
class List {
	string[] mylist; string mycmd;
	public Gtk.Widget show(string[] list, string cmd, string title, bool show_search){
		mylist = list; mycmd = cmd;
		var l = new ListExec(list);
		l.row_selected.connect((row)=>{
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
	int cindex = 0;	// 颜色索引，建立颜色散列表
	HashTable<string, int> hash = new HashTable<string, int> (str_hash, str_equal);

// 构造函数，参数：list为“显示文字#标签”
	public ListExec(string[] list){
		int maxflaglen = 1;
		foreach (string s in list){	// 计算标签最大长度
			string[] a = s.split("#", 2);
			if(a[1]==null){a[1]="";}
			if(maxflaglen < a[1].length){maxflaglen = a[1].length;}
		}
		foreach (string s in list){
			if(s==""){continue;}
			var lbl = new Gtk.Label("");
			lbl.xalign = (float)0;
// 处理彩色的标签
			string[] a = s.split("#", 2);
			string name = a[0].substring(a[0].last_index_of("/")+1);	//显示时，去掉路径
			if(a[1]==null){a[1]="";}	// 空字符串也有颜色
			string fill = string.nfill(maxflaglen-a[1].length,' ');	// 前导填充空格
			if(! hash.contains(a[1])){	// 增加颜色索引
				hash.insert(a[1], cindex); cindex++; cindex%=color.length;
			}
			lbl.set_markup(fill+"<span background=\""+color[hash.get(a[1])]+
			"\"	foreground=\"#ffffff\"><b> "+a[1]+" </b></span><big>  "+name+" </big>");
			this.insert(lbl, -1);
		}
	}
}
//----------------------------------------------------------
//----------------------------------------------------------

