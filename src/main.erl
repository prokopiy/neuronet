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


loop() ->
  receive
    A ->
      io:format("main:loop(): ~w ~n", [A]),
      loop()
  after
    10000 ->
      true
  end.


start() ->
  {_Date, Time} = calendar:local_time(),
  random:seed(Time),

  io:format("Node = ~w~n", [node()]),

  net:test(),

%%   {mailbox, 'dice@prokopiy-pc'} ! {login, self(), {"prokopiy", "5zR8u8NsJS9vFbF4dNYn"}},



  loop(),
  io:get_line("Press <Enter> to exit...").
