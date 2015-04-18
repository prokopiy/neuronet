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

%%
call(Pid, Message) ->
  Pid ! {request, self(), Message},
  receive
    {reply, Pid, Reply} -> Reply;
    {reply, OtherPid, Reply} ->
      io:format("Other ~w reply = ~w~n", [OtherPid, Reply])
  end.


loop() ->
  receive
    A ->
      io:format("loop: ~w ~n", [A]),
      loop()

  after
    21000 ->
      true
  end.

start() ->
  io:format("Node = ~w~n", [node()]),

  N1 = neuron:new(),
  N2 = neuron:new(),
  link:register_many_to_many([N1], [N2], [1.0]),


  R1 = call(N1, print),
  io:format("Reply ~w~n", [R1]),

  R2 = call(N1, {pulse, self(), 1.0}),
  io:format("Reply ~w~n", [R2]),

%%   erlang:set_cookie(node(), pass),
%%   net_adm:ping('bar@Prokopiy-PC'),

%%   Serv = server:start(),
%%   io:format("~w~n", [Serv]),

  TT = math:tanh(1),
    
  loop(),

  io:get_line("Press <Enter> to exit...")

.
