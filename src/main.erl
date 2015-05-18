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
    1000 ->
      true
  end.

start() ->
  io:format("Node = ~w~n", [node()]),

%%   N1 = neuron:new(0),
%%   N2 = neuron:new(1),
%%   N3 = neuron:new(2),
%%   link:register_neuron_to_neuron(N1, N3, 0.5),
%%   link:register_neuron_to_neuron(N2, N3, 1.0),
%%
%%   neuron:pulse(N1, 0.66),
%%   neuron:pulse(N2, 0.88),
%%   neuron:pulse(N1, 0.11),
%%   neuron:pulse(N2, 0.22),
%%   neuron:pulse(N1, 0.44),
%%   neuron:pulse(N2, 0.55),

%   R1 = neuron:call(N1, neuron:print_message()),
%   io:format("Reply ~w~n", [R1]),
%   R2 = neuron:call(N2, neuron:print_message()),
%   io:format("Reply ~w~n", [R2]),
%   R3 = neuron:call(N3, neuron:print_message()),
%   io:format("Reply ~w~n", [R3]),

%%   L = net:generate_layer([0,1,2,3]),
%%   io:format("Layer = ~w~n", [L]),

  net:test(),

  loop(),
  io:get_line("Press <Enter> to exit...").
