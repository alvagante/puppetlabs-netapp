require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_volume).provide(:netapp_volume, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Volume creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::Netapp_volume: creating Netapp Volume #{@resource[:name]} of initial size #{@resource[:initsize]} in Aggregate #{@resource[:aggregate]} using space reserve of #{@resource[:spaceres]}.")
    result = transport.invoke("volume-create", "volume", @resource[:name], "size", @resource[:initsize], "containing-aggr-name", @resource[:aggregate], "space-reserve", @resource[:spaceres])
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} creation failed due to #{result.result_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Volume #{@resource[:name]} creation failed due to #{result.result_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} created successfully. \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_volume: destroying Netapp Volume #{@resource[:name]}")
    # Check if volume is online. 
    result = transport.invoke("volume-list-info", "volume", @resource[:name])
    if(result.results_status == "passed")
      volumes = result.child_get("volumes")
      volume_info = volumes.child_get("volume-info")
      plexes = volume_info.child_get("plexes")
      plex_info = plexes.child_get("plex-info")
      online = plex_info.child_get_string("is-online")
      if(online)
        Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} is currently online. Offlining... ")
        result = transport.invoke("volume-offline", "name", @resource[:name])
        if(result.results_status == "failed")
          Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} offline failed due to #{result.result_reason}. \n")
          raise Puppet::Error, "Puppet::Device::Netapp Volume #{@resource[:name]} offline failed due to #{result.result_reason} \n."
          return false
        else 
          Puppet.debug("Puppet::Provider::Netapp_volume: Volume taken offline successfully. \n")
        end
      end
    end
    result = transport.invoke("volume-destroy", "name", @resource[:name])
    Puppet.debug("Puppet::Provider::Netapp_volume: Volume destroy output: " + result.sprintf() + "\n")
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume #{@resource[:name]} wasn't destroyed due to #{result.result_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Volume #{@resource[:name]} destroy failed due to #{result.result_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume destroyed successfully. \n")
      return true
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_volume: checking existance of Netapp Volume #{@resource[:name]}")
    result = transport.invoke("volume-list-info", "volume", @resource[:name])
    Puppet.debug("Puppet::Provider::Netapp_volume: Vol Info: " + result.sprintf() + "\n")
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume doesn't exist. \n")
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_volume: Volume exists. \n")
      return true
    end

  end
  
end