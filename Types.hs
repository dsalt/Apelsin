module Types (
	module Control.Concurrent.STM
	, Bundle(..)
) where
import Graphics.UI.Gtk
import Config
import ClanFetcher
import Control.Concurrent.STM
import Network.Tremulous.Protocol

data Bundle = Bundle {
	  mpolled	:: !(TMVar PollMasters)
	, mconfig	:: !(TMVar Config)
	, mclans	:: !(TMVar [Clan])
	, parent	:: !Window
	}
