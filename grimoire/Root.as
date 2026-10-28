package grimoire
{
	import adobe.utils.ProductManager;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.ui.Keyboard;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.utils.getQualifiedClassName;
	import flash.utils.Timer;
	import flash.external.ExternalInterface;
	import flash.filters.GlowFilter;
	import flash.filesystem.File;
	import grimoire.game.*;
	import grimoire.tools.*;

	public class Root extends MovieClip
	{
		private var sTitle:String = "Grimlite Li";
		private const sURL:String = "https://game.aq.com/game/";
		private const versionURL:String = this.sURL + "api/data/gameversion";
		private const LoginURL = this.sURL + "api/login/now";
		private var urlLoader:URLLoader;
		private var loader:Loader;
		private var loaderVars:Object;
		private var external:Externalizer;
		private var sFile:String;
		private var sBG:String;
		private var isEU:Boolean;
		private var isWeb:Boolean;
		private var doSignup:Boolean;
		private var stg:Object;
		private var vars:URLVariables;
		private var serversLoader:URLLoader = new URLLoader();
		private var bgLoader:Loader;
		private var bgSWF:Object;

		public static var GameDomain:ApplicationDomain;
		public static var Game:*;
		public static const TrueString:String = "\"True\"";
		public static const FalseString:String = "\"False\"";
		public static var Username:String;
		public static var Password:String;
		public static var Instance:Root;
		public var mcLoading:MovieClip;

		public function Root()
		{
			Instance = this;
			addEventListener(Event.ADDED_TO_STAGE, this.OnAddedToStage);
		}

		private function OnAddedToStage(event:Event) : void
		{
			removeEventListener(Event.ADDED_TO_STAGE, this.OnAddedToStage);
			Security.allowDomain("*");
			this.urlLoader = new URLLoader();
			this.urlLoader.addEventListener(Event.COMPLETE, this.OnDataComplete);
			this.urlLoader.load(new URLRequest(this.versionURL));
		}

		private function OnDataComplete(event:Event) : void
		{
			this.urlLoader.removeEventListener(Event.COMPLETE,this.OnDataComplete);
			var vars:Object = JSON.parse(event.target.data);
			this.sFile = vars.sFile + "?ver=" + vars.sVersion;
			// this.sTitle = vars.sTitle;
			this.isEU = vars.isEU == "true";
			this.isWeb = false;
			this.doSignup = false;
			this.sBG = vars.sBG;
			this.loaderVars = vars;
			this.LoadGame();
		}

		private function LoadGame() : void
		{
			this.external = new Externalizer();
			this.external.init(this);
			this.loader = new Loader();
			this.loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, this.OnProgress);
			this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.OnComplete);
			this.loader.load(new URLRequest(this.sURL + "gamefiles/" + this.sFile));
			this.mcLoading.strLoad.text = "Loading 0%";
		}

		private function OnProgress(event:ProgressEvent) : void
		{
			this.external.call("progress", Math.round(Number(event.currentTarget.bytesLoaded / event.currentTarget.bytesTotal) * 100));     
			var percent:int = event.currentTarget.bytesLoaded / event.currentTarget.bytesTotal * 100;       
			this.mcLoading.strLoad.text = "Loading " + percent + "%";
		}

		private function OnComplete(event:Event) : void
		{
			this.loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, OnProgress);
			this.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, OnComplete);

			this.stg = stage;
			this.stg.removeChildAt(0);
			Game = this.stg.addChildAt(event.currentTarget.content, 0);
			//Game = this.stg.addChild(this.loader.content);
			
			for (var param:String in root.loaderInfo.parameters)
			{
				Game.params[param] = root.loaderInfo.parameters[param];
			}
			Game.params.vars = this.loaderVars;
			Game.params.sURL = this.sURL;
			Game.params.sBG = this.sBG;
			Game.params.sTitle = this.sTitle;
			Game.params.loginURL = this.LoginURL;
			Game.params.isEU = this.isEU;
			Game.params.isWeb = this.isWeb;
			Game.params.doSignup = this.doSignup;
			Game.params.test = false;
			
			Game.sfc.addEventListener(SFSEvent.onExtensionResponse, this.OnExtensionResponse);
			GameDomain = LoaderInfo(event.target).applicationDomain;
			
			Game.sfc.addEventListener(SFSEvent.onConnectionLost, this.OnConnectionLost);
			Game.sfc.addEventListener(SFSEvent.onConnection, this.OnConnection);
			Game.sfc.addEventListener(SFSEvent.onJoinRoomError, this.OnJoinRoomError);
			Game.sfc.debug = True;
			Game.sfc.addEventListener(SFSEvent.onDebugMessage, this.PacketReceived);
			Game.addEventListener(MouseEvent.CLICK, this.onGameClick);	
			Game.loginLoader.addEventListener(Event.COMPLETE, this.OnLoginComplete);	
			//getServers();
			addEventListener(Event.ENTER_FRAME, this.EnterFrame);
			trace("OnComplete Stage");
			this.LoadAstolfo();
		}

		private function onGameClick(event:MouseEvent) : void
      {
         if(event == null)
         {
            return;
         }
         var className:String = getQualifiedClassName(event.target.parent);
         trace(className);
         this.external.debug(GetDisplayPath(event.target as DisplayObject));
         this.external.debug("Target : " + event.target.name + " (" + event.target + ")");
         this.external.debug("Parent : " + event.target.parent.name + " (" + event.target.parent + ")");
         if(event.target.parent.name == "monsterDropsPanel")
         {
            this.external.call("openWebsite","https://aqwwiki.wikidot.com/" + Game.ui.getChildByName("monsterDropsPanel").getChildAt(4).text);
         }
         switch(event.target.name)
         {
            case "btCharPage":
               this.external.call("openWebsite","https://account.aq.com/CharPage?id=" + event.target.parent.txtUserName.text);
               return;
            case "btnWiki":
               if(event.target.parent.parent.parent.name == "qRewardPrev")
               {
                  this.external.call("openWebsite","https://aqwwiki.wikidot.com/" + Game.ui.getChildByName("qRewardPrev").cnt.strTitle.text);
               }
               else if(className.indexOf("LPFFrameItemPreview") > -1)
               {
                  this.external.call("openWebsite","https://aqwwiki.wikidot.com/" + event.target.parent.tInfo.getLineText(0));
               }
               else if(className.indexOf("LPFFrameHousePreview") > -1)
               {
                  this.external.call("openWebsite","https://aqwwiki.wikidot.com/" + Game.ui.mcPopup.getChildByName("mcInventory").previewPanel.frames[3].mc.tInfo.getLineText(0));
               }
               else if(className.indexOf("mcQFrame") > -1)
               {
                  this.external.call("openWebsite","https://cse.google.com/cse?oe=utf8&ie=utf8&source=uds&safe=active&sort=&cx=015511893259151479029:wctfduricyy&start=0#gsc.tab=0&gsc.q=" + Game.getInstanceFromModalStack("QFrameMC").qData.sName);
               }
               return;
            case "hit":
               if(className.indexOf("cProto") > -1 && event.target.parent.ti.text.toLowerCase() == "wiki monster")
               {
                  this.external.call("openWebsite","https://aqwwiki.wikidot.com/" + Game.world.myAvatar.target.objData.strMonName || "monsters");
               }
               return;
            default:
               return;
         }
      }

		private function LoadAstolfo() : void
		{
			this.external.debug("Loading background JPG");
			this.bgLoader = new Loader();
			this.bgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.OnAstolfoComplete);
			this.bgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.OnAstolfoError);

			this.bgLoader.load(new URLRequest("Loader/bg.jpg"));
		}

		private function OnAstolfoComplete(event:Event) : void
		{
			this.bgSWF = this.bgLoader.content;
			if (Game && this.bgSWF)
			{
				// Game.addChildAt(this.bgSWF, 0);
				// this.bgSWF.visible = false;
				this.external.debug("Background JPG loaded and added to Game container");
			}
		}

		private function OnAstolfoError(event:IOErrorEvent) : void
		{
			this.external.debug("Error loading background JPG: " + event.text);
		}

		private function getServers() 
		{
			var urlServers:String = "https://game.aq.com/game/api/data/servers";
			var request:URLRequest = new URLRequest(urlServers);
			request.method = URLRequestMethod.GET;
			serversLoader.addEventListener(Event.COMPLETE, this.OnServersLoaded);
			try 
			{
				serversLoader.load(request);
			}
			catch(e) 
			{
				trace("Failed to getting servers info.")
			}
		}

		private function OnServersLoaded(event:Event) 
		{
			var vars:Object = JSON.parse(event.target.data);
			this.external.call("getServers2", JSON.stringify(vars));
			serversLoader.removeEventListener(Event.COMPLETE, this.OnServersLoaded);
		}

		private function OnConnectionLost(param1) : void
		{
			this.external.call("connection", "OnConnectionLost");
			Game.gotoAndPlay(Game.litePreference.data.bCharSelect ? "Select" : "Login");
		}
		
		private function OnConnection(param1) : void
		{
			this.external.call("connection", "OnConnection");
			RemoveCharSelectUI();
		}

		private function OnJoinRoomError(param1) : void
		{
			this.external.debug("OnJoinRoomError");
		}

		private function OnLoginComplete(event:Event) : void
		{
			//event.target.data = String(ExternalInterface.call("modifyServers", event.target.data));
			var vars:Object = JSON.parse(event.target.data);
			this.external.call("getServers", JSON.stringify(vars))
			//vars.login.iAccess = 70;
			vars.login.iUpg = 10;
			vars.login.iUpgDays = 999;
			for (var s in vars.servers) 
			{
				vars.servers[s].sName = vars.servers[s].sName;
			}
			event.target.data = JSON.stringify(vars);
			if (Game.mcCharSelect) Game.mcCharSelect.Game.objLogin = vars;
		}

		private function EnterFrame(event:Event) : void
		{
			if (Game.mcLogin != null && Game.mcLogin.ni != null && Game.mcLogin.pi != null && Game.mcLogin.btnLogin != null)
			{
				//removeEventListener(Event.ENTER_FRAME, EnterFrame); NO NEED TO REMOVE THE LISTENER
				Game.mcLogin.btnLogin.removeEventListener(MouseEvent.CLICK, this.onLoginClick);
				Game.mcLogin.btnLogin.addEventListener(MouseEvent.CLICK, this.onLoginClick);

				Game.mcLogin.removeEventListener(KeyboardEvent.KEY_DOWN, this.onLoginKeyEnter);
				Game.mcLogin.addEventListener(KeyboardEvent.KEY_DOWN, this.onLoginKeyEnter);
			}

			if (Game.mcCharSelect != null) 
			{
				Game.mcCharSelect.btnLogin.removeEventListener(MouseEvent.CLICK, Game.mcCharSelect.onBtnLogin);
				Game.mcCharSelect.btnLogin.addEventListener(MouseEvent.CLICK, this.onBtnLogin);

				Game.mcCharSelect.btnServer.removeEventListener(MouseEvent.CLICK, Game.mcCharSelect.onBtnServer);
				Game.mcCharSelect.btnServer.addEventListener(MouseEvent.CLICK, this.onBtnServer);

				Game.mcCharSelect.passwordui.txtPassword.removeEventListener(KeyboardEvent.KEY_DOWN, Game.mcCharSelect.passwordui.onPasswordEnter);
				Game.mcCharSelect.passwordui.txtPassword.addEventListener(KeyboardEvent.KEY_DOWN, this.onPasswordEnter);
			}

			if (Game.mcConnDetail != null) 
			{
				Game.mcConnDetail.addEventListener(Event.ADDED_TO_STAGE, AddedStageConnDetail);
				if (Game.mcConnDetail.txtDetail.text.indexOf("Error loading bank") >= 0 ||
					Game.mcConnDetail.txtDetail.text.indexOf("Communication with server has been lost") >= 0) 
				{
					Game.mcConnDetail.hideConn();
				}
			}
		}

		private function AddedStageConnDetail(event:Event) : void
		{
			Game.mcConnDetail.removeEventListener(Event.ADDED_TO_STAGE, AddedStageConnDetail);
			var o:Object = {
    			text: Game.mcConnDetail.txtDetail.text,
    			btnBack: Game.mcConnDetail.btnBack.visible 
			};
			this.external.call("currentConnDetail", JSON.stringify(o));
			trace("Added Conn Detail : " + JSON.stringify(o));
			if (Game.mcConnDetail.btnBack.visible) HideConnMC();
		}

		private function onLoginClick(event:MouseEvent) : void
		{
			Username = Game.mcLogin.ni.text;
			Password = Game.mcLogin.pi.text;
		}

		private function onLoginKeyEnter(event:KeyboardEvent) : void 
		{
			if(event.keyCode == Keyboard.ENTER) 
			{
				Username = Game.mcLogin.ni.text;
				Password = Game.mcLogin.pi.text;
			}
		}

		public function onBtnServer(event:MouseEvent) : void
		{
			Game.mcCharSelect.skipServers = false;
			var loginData:* = Game.mcCharSelect.mngr.displayAvts[Game.mcCharSelect.pos].loginInfo;
			if(loginData.bAsk)
			{
				Game.mcCharSelect.utl.close(1);
				Game.mcCharSelect.passwordui.pos = Game.mcCharSelect.pos;
				Game.mcCharSelect.passwordui.bCharOpts = false;
				Game.mcCharSelect.passwordui.visible = true;
			}
			else
			{
				Login();
				RemoveCharSelectUI();
			}
		}

		private function onBtnLogin(event:MouseEvent): void
		{
			Game.mcCharSelect.skipServers = true;
			Login();
			myTimer.addEventListener(TimerEvent.TIMER, this.WaitServersLoad);
			myTimer.start();
			RemoveCharSelectUI();
		}

		private function onPasswordEnter(event:KeyboardEvent) : void
		{
			if(event.keyCode == Keyboard.ENTER)
			{
				var relPass:* = Game.mcCharSelect.mngr.displayAvts[Game.mcCharSelect.pos].loginInfo;
				if(relPass.strPassword != Game.mcCharSelect.passwordui.txtPassword.text)
				{
					Game.mcCharSelect.passwordui.txtWarning.visible = true;
				}
				else if(Game.mcCharSelect.passwordui.bCharOpts)
				{
					Game.mcCharSelect.charoptionsui.setOff();
				}
				else
				{
					Login();
					RemoveCharSelectUI();
				}
			}
		}

		private var myTimer:Timer = new Timer(200);
		private function WaitServersLoad(event: TimerEvent): void
		{
			if (AutoRelogin.AreServersLoaded() == Root.TrueString) 
			{
				myTimer.removeEventListener(TimerEvent.TIMER, this.WaitServersLoad);
				myTimer.stop();
				var server:String = Game.mcCharSelect.mngr.displayAvts[Game.mcCharSelect.pos].server;
				AutoRelogin.Connect(server);
			}
		}

		private function RemoveCharSelectUI() : void
		{
			if(Game.mcCharSelect != null) {
				if (Game.mcCharSelect.parent != null) {
					MovieClip(Game.mcCharSelect.parent).removeChild(Game.mcCharSelect);
					this.external.debug("mcCharSelect cleared");
				}
			}
		}

		private function Login(): void 
		{
			Username = Game.mcCharSelect.mngr.displayAvts[Game.mcCharSelect.pos].loginInfo.strUsername;
			Password = Game.mcCharSelect.mngr.displayAvts[Game.mcCharSelect.pos].loginInfo.strPassword;
			AutoRelogin.Login();
		}
		
		private function OnExtensionResponse(packet:*):void
		{
			this.external.call("pext", JSON.stringify(packet));
		}
		
		private function PacketReceived(packet:*):void
		{
			if (packet.params.message.indexOf("%xt%zm%") > -1)
			{
				this.external.call("packetFromClient", packet.params.message.replace(/^\s+|\s+$/g, ''));
			} 
			else 
			{
				this.external.call("packetFromServer", ProcessPacket(packet.params.message));				
			}
		}
		
		private function ProcessPacket(packet:String) : String
		{
			var index:int = 0;
			if(packet.indexOf("[Sending - STR]: ") > -1)
			{
				packet = packet.replace("[Sending - STR]: ","");
			}
			if(packet.indexOf("[ RECEIVED ]: ") > -1)
			{
				packet = packet.replace("[ RECEIVED ]: ","");
			}
			if(packet.indexOf("[Sending]: ") > -1)
			{
				packet = packet.replace("[Sending]: ","");
			}
			if(packet.indexOf(", (len: ") > -1)
			{
				index = packet.indexOf(", (len: ");
				packet = packet.slice(0, index);
			}
			return packet;
		}

		public function ServerName() : String
		{
			return "\"" + Game.objServerInfo.sName + "\"";
		}
		
		public function RealAddress() : String
		{
			return "\"" + Game.objServerInfo.RealAddress + "\"" ;
		}

		public function RealPort() : String
		{
			return "\"" + Game.objServerInfo.RealPort + "\"" ;
		}

		public function GetUsername() : String
		{
			return "\"" + Username + "\"";
		}

		public function GetPassword() : String
		{
			return "\"" + Password + "\"";
		}

		public function SetFPS(fps:String) : void
		{
			this.stg.frameRate = parseInt(fps);
		}

		public function SetTitle(title:String) : void
		{
			Game.mcLogin.mcLogo.txtTitle.htmlText = "<font color=\"#FFB231\">New Release:</font> " + title;
			Game.params.sTitle.htmlText = "<font color=\"#FFB231\">New Release:</font> " + title;
		}

		public function SendMessage(msg:String) : void
		{
			Game.chatF.pushMsg("server", msg, "SERVER", "", 0);
		}

		public function IsConnMCBackButtonVisible() : String
		{
			return Game.mcConnDetail.btnBack.visible && Game.mcConnDetail.stage != null ? TrueString : FalseString;
		}

		public function GetConnMC() : String
		{
			return Game.mcConnDetail.stage == null ? "" : Game.mcConnDetail.txtDetail.text;
		}

		public function HideConnMC() : void
		{
			Game.mcConnDetail.hideConn();
		}

		public function SetBackgroundSWFVisibility(visible:Boolean) : void
		{
			if (this.bgSWF && Game)
			{
				if (visible) {
					// Check if bgSWF is not already in Game container
					if (!Game.contains(this.bgSWF)) {
						Game.addChildAt(this.bgSWF, 0);
					}
				} else {
					// Only remove if bgSWF is actually at index 0
					if (Game.numChildren > 0 && Game.getChildAt(0) == this.bgSWF) {
						Game.removeChildAt(0);
					}
				}
				// this.bgSWF.visible = visible;
			}
		}
	}
}
