-module(db_host_info).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").

-define(TABLE,host_info).
-define(RECORD,host_info).
-record(host_info,{
		   host_id,
		   ip,
		   ssh_port,
		   uid,
		   pwd,
		   geo_location,
		   status        % absent,avaiable,member
		  }).

% Start Special 

% End Special 
create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables([?TABLE], 20000).


create_table_copies(CopyType,NodeList)->
    case CopyType of
	ram->
	    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
					 {ram_copies,NodeList}]);
	disc->
	    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
					 {ram_copies,NodeList}]);
	disc_only_copies ->
	    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
					 {disc_only_copies,NodeList}])
    end,
    mnesia:wait_for_tables([?TABLE], 20000).

add_node(Node,StorageType)->
    Result=case mnesia:change_config(extra_db_nodes, [Node]) of
	       {ok,[Node]}->
		   mnesia:add_table_copy(schema, node(),StorageType),
		   mnesia:add_table_copy(?TABLE, node(), StorageType),
		   Tables=mnesia:system_info(tables),
		   mnesia:wait_for_tables(Tables,20*1000);
	       Reason ->
		   Reason
	   end,
    Result.

create(HostId,Ip,SshPort,UId,Pwd,GeoLocation,Status)->
    Record=#?RECORD{
		    host_id=HostId,
		    ip=Ip,
		    ssh_port=SshPort,
		    uid=UId,
		    pwd=Pwd,
		    geo_location=GeoLocation,
		    status=Status
		   },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

member(Object)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.host_id==Object])),
    Member=case Z of
	       []->
		   false;
	       _->
		   true
	   end,
    Member.

ssh_info(Object)->
    read(Object,ssh_info).
location(Object)->
    read(Object,location).
status(Object)->
    read(Object,status).
read(Object,Key)->
    Return=case read(Object) of
	       []->
		   {error,[eexist,Object,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{_HostId,Ip,SshPort,UId,Pwd,GeoLocation,Status}] ->
		   case  Key of
		       ssh_info->
			   {Ip,SshPort,UId,Pwd};
		       location->
			   GeoLocation;
		       status->
			   Status;
		       Err ->
			   {error,['Key eexists',Err,?FUNCTION_NAME,?MODULE,?LINE]}
		   end
	   end,
    Return.

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{HostId,Ip,SshPort,UId,Pwd,GeoLocation,Status}||{?RECORD,HostId,Ip,SshPort,UId,Pwd,GeoLocation,Status}<-Z].

read(Object)->
    Z=do(qlc:q([X || X <- mnesia:read({?TABLE,Object})])),
    Result=case Z of
	       {error,Reason}->
		    {error,Reason};
	       _->
		   [{HostId,Ip,SshPort,UId,Pwd,GeoLocation,Status}||{?RECORD,HostId,Ip,SshPort,UId,Pwd,GeoLocation,Status}<-Z]
	   end,
    Result.

delete(Object) ->
    F = fun() -> 
		mnesia:delete({?TABLE,Object})
		    
	end,
    mnesia:transaction(F).


do(Q) ->
  F = fun() -> qlc:e(Q) end,
    
    Result = case mnesia:transaction(F) of
		 {atomic, Val}->
		     Val;
		 Error->
		     {error,[Error,?FUNCTION_NAME,?MODULE,?LINE]}
	     end,
    Result.

%%-------------------------------------------------------------------------
