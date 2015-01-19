%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Дек. 2014 12:26
%%%-------------------------------------------------------------------
-module(server).
-author("prokopiy").

%% API
-export([start/0, init/0]).


start() ->
  {A1, A2, A3} = now(),
  random:seed(A1, A2, A3),
%%   register(server, spawn(server, init, [])).
  spawn(server, init, []).

init() ->
  loop([]).

allocate(Data, {Pid, Id}, L) ->
  Net = net:generate_perceptron(L),
  {[{{Pid, Id}, Net} | Data], {ok, Id}}.



loop(Data) ->
  receive
    {request, Pid, {allocate, L}} ->
      Id = random:uniform(10000000),
      {NewD, Reply} = allocate(Data, {Pid, Id}, L),
      io:format("server:Data = ~w~n", [NewD]),
      io:format("server:reply(~w,~w)~n", [Pid, Reply]),
      reply(Pid, Reply),
      loop(NewD);
    {request, Pid, {pulse, UID, L}} ->
      io:format("server:UID = ~w~n", [UID]),
      {{Pid, UID}, NetPid} = lists:keyfind({Pid, UID}, 1, Data),
      io:format("server:NetPid = ~w~n", [NetPid]),
      NetPid ! {self(), pulse, L},
      loop(Data);
    {reply, NetPid, {effect, Value}} ->
      {{Pid, _}, NetPid} = lists:keyfind(NetPid, 2, Data),
      io:format("server:reply NetPid = ~w, source=~w~n", [NetPid, Pid]),
      Reply = {ok, Value},
      reply(Pid, Reply),
      loop(Data);
    Other ->
      io:format("~w~n", [Other])

  after 150000 ->
    io:format("Server stop~n", []),
    true

  end.



reply(Pid, Reply) ->
  Pid ! {reply, Reply}.