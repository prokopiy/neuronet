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
      io:format("loop: ~w ~n", [A]),
      loop()

  after
    1000 ->
      true
  end.

start() ->
  io:format("Node = ~w~n", [node()]),

  N1 = neuron:new(0),
%%   N2 = neuron:new(1),
  N3 = neuron:new(2),
%%   link:register_neuron_to_neuron(N1, N3, 0.5),
%%   link:register_neuron_to_neuron(N2, N3, 1.0),
%%
%%   N1 ! {request, self(), {pulse, self(), 0.66}},
%%   N2 ! {request, self(), {pulse, self(), 0.88}},
%%   N1 ! {request, self(), {pulse, self(), 0.11}},
%%   N2 ! {request, self(), {pulse, self(), 0.22}},
%%   N1 ! {request, self(), {pulse, self(), 0.44}},
%%   N2 ! {request, self(), {pulse, self(), 0.55}},
%%
%%   R1 = neuron:call(N1, neuron:print_message()),
%%   io:format("Reply ~w~n", [R1]),
%%   R2 = neuron:call(N2, neuron:print_message()),
%%   io:format("Reply ~w~n", [R2]),
%%   R3 = neuron:call(N3, neuron:print_message()),
%%   io:format("Reply ~w~n", [R3]),

%%   L = net:generate_layer([0,1,2,3]),
%%   io:format("Layer = ~w~n", [L]),

  net:test(),

  loop(),
  io:get_line("Press <Enter> to exit...").


