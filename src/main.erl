%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Дек. 2014 1:38
%%%-------------------------------------------------------------------
-module(main).
-author("prokopiy").

%% API
-export([start/0]).


call(Message) ->
  server ! {request, self(), Message},
  receive
    {reply, Reply} -> Reply
  end.


start() ->
  io:format("Node = ~w~n", [node()]),
%%   erlang:set_cookie(node(), pass),
%%   net_adm:ping('bar@Prokopiy-PC'),
%%   f(3),

  Serv = server:start(),
  io:format("~w~n", [Serv]),

%%   {RT, UID} = call({allocate, [3,2,1]}),
%%   if
%%     RT == ok ->
%%       io:format("allocate - ~w~n", [RT]),
%%       {RT2, R2} = call({pulse, UID, [1,1,1]}),
%%       if
%%         RT2 == ok ->
%%           io:format("~w pulse - ~w result = ~w~n", [self(), RT2, R2])
%%       end;
%%     RT == error ->
%%       false
%%   end,


  io:get_line(">")

.
