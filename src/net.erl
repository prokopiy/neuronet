%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Дек. 2014 21:52
%%%-------------------------------------------------------------------
-module(net).
-author("prokopiy").

%% API
-export([loop/1, new/2, test/0, print/1, stop/1, pulse/2]).


new(Layers, Memory_length) ->

  Receptors_size = lists:nth(1, Layers),
  L1 = generate_layer(lists:duplicate(Receptors_size, 0)),

  M = lists:flatten(lists:map(fun(P) -> L = generate_layer(lists:seq(0, Memory_length)), neuron:register_link(P, L, 1),
    L end, L1)),

  Hidden_layers = lists:sublist(Layers, 2, length(Layers) - 2),
  L2 = generate_hidden_layers(Hidden_layers),

  Effectors_size = lists:last(Layers),
  L3 = generate_layer(lists:duplicate(Effectors_size, 0)),

  T = generate_layer(lists:duplicate(2, 0)),


  link:register_layer_to_layer(M, lists:nth(1, L2)),
  link:register_between_layers(L2),
  link:register_layer_to_layer(lists:last(L2), L3),
  link:register_layer_to_layer(T, lists:flatten(L2 ++ L3)),

  Data = #{
    hidden_layers => L2,
    receptors => L1,
    effectors => L3,
    memory => M,
    tone => T,
    last_out => []

  },
  spawn(net, loop, [Data]).


test() ->
  Net1 = new([2, 3, 2, 1], 2),
%%   print(Net1),
  pulse(Net1, [1, 1]),
  true_output(Net1, [1]),
  pulse(Net1, [1, 1]),
  true_output(Net1, [0]),
  pulse(Net1, [0, 1]),
  true_output(Net1, [0]),
  pulse(Net1, [0, 1]),
  true_output(Net1, [1]),
  pulse(Net1, [1, 1]),
  true_output(Net1, [1]),
  pulse(Net1, [1, 1]),
  true_output(Net1, [0]),

%%    back_error(Net1, [-0.5]),
%%   io:get_line("Press111111111 <Enter> to exit..."),
%%   print(Net1),
  true.


print(Net) when is_pid(Net) ->
  Net ! {request, self(), print}.

stop(Net) when is_pid(Net) ->
  Net ! {request, self(), stop}.

pulse(Net, Powers) when is_pid(Net), is_list(Powers) ->
  Net ! {request, self(), {pulse, Powers}},
  receive
    {reply, Net, {effect, Reply}} -> Reply
  end.

back_error(Net, Error) when is_pid(Net) ->
  Net ! {request, self(), {back_error, Error}},
  receive
    {reply, Net, {confirm_back_error, ok}} -> ok
  end.

true_output(Net, L) when is_pid(Net), is_list(L) ->
  Net ! {request, self(), {true_output, L}},
  receive
    {reply, Net, {confirm_true_output, ok}} -> ok
  end.



generate_layer(A) ->
  generate_layer(A, []).
generate_layer([], Acc) ->
  Acc;
generate_layer([H | T], Acc) ->
  N = neuron:new(H),
  generate_layer(T, Acc ++ [N]).


generate_hidden_layers(L) ->
  generate_hidden_layers(L, []).
generate_hidden_layers([], Acc) ->
  Acc;
generate_hidden_layers([H | T], Acc) ->
  L = generate_layer(lists:duplicate(H, 0)),
  generate_hidden_layers(T, Acc ++ [L]).


pulse_to_layer([], []) ->
  true;
pulse_to_layer([NH | NT], [PH | PT]) when is_pid(NH) ->
  neuron:pulse(NH, PH),
  pulse_to_layer(NT, PT).



get_effect(Effectors, EffectAcc) when is_list(Effectors), is_map(EffectAcc) ->
%%   io:format("EFFFFFFFFFFFFFFFFFF,~w~n", [Effectors]),
  case {length(Effectors), maps:size(EffectAcc)} of
    {_X, _X} ->
      R = lists:map(fun(P) -> maps:get(P, EffectAcc) end, Effectors),
      R;
    {_X, _Y} ->
%%       io:format("~w X,Y=,~w, ~w~n", [self(), _X, _Y]),
      receive
        {reply, Pid, {effect, Value}} ->
          NewEffectAcc = maps:put(Pid, Value, EffectAcc),
          get_effect(Effectors, NewEffectAcc)
      after
        25000 ->
          {error, timeout}
      end
  end.

confirm_back_error(Effectors, Acc) when is_list(Effectors), is_map(Acc) ->
  case {length(Effectors), maps:size(Acc)} of
    {_X, _X} ->
      {ok, ok};
    {_X, _Y} ->
      receive
        {reply, Pid, {confirm_back_error, Value}} ->
%%           io:format("~w confirm_back_error Pid=,~w, ~w~n", [self(), Pid, Value]),
          NewAcc = maps:put(Pid, Value, Acc),
          confirm_back_error(Effectors, NewAcc)
      after
        25000 ->
          {error, timeout}
      end
  end.


loop(Data) ->
  receive
    {reply, _, ok} ->
      loop(Data);
    {request, _, stop} ->
      true;
    {request, Pid, print} ->
      io:format("Net~w ~w~n", [self(), Data]),
      io:format("Receptor layer:~n"),
      neuron:print(maps:get(receptors, Data)),
      io:format("Memory layer:~n"),
      neuron:print(maps:get(memory, Data)),
      io:format("Hidden layer:~n"),
      lists:foreach(fun(P) -> neuron:print(P) end, maps:get(hidden_layers, Data)),
      io:format("Effector layer:~n"),
      neuron:print(maps:get(effectors, Data)),
      io:format("Tone layer:~n"),
      neuron:print(maps:get(tone, Data)),
%%       Pid ! {reply, self(), ok},
      loop(Data);
    {request, Pid, {pulse, PowerList}} ->
      Receptors = maps:get(receptors, Data),
      Tone = maps:get(tone, Data),
      pulse_to_layer(Receptors, PowerList),
      pulse_to_layer(Tone, [-1, 1]),
      Effect = get_effect(maps:get(effectors, Data), #{}),
      Pid ! {reply, self(), {effect, Effect}},
      NewData1 = maps:put(last_out, Effect, Data),
      io:format("Net~w: send effect ~w to ~w~n", [self(), Effect, Pid]),
      loop(NewData1);

    {request, Pid, {back_error, Errors}} when is_list(Errors) ->
      io:format("Net~w: request error = ~w ~n", [self(), Errors]),

      Effectors = maps:get(effectors, Data),

      Zip = lists:zip(Effectors, Errors),

      lists:foreach(fun(P) -> {N, E} = P, N ! {request, self(), {back_error, E}} end, Zip),

      confirm_back_error(Effectors, #{}),
      Pid ! {reply, self(), {confirm_back_error, ok}},
      loop(Data);

    {request, Pid, {true_output, L}} ->
%%       io:format("Net~w: request true_output = ~w ~n", [self(), L]),

      Last_out = maps:get(last_out, Data),
      Effectors = maps:get(effectors, Data),
      Errors = lists:zipwith(fun(X, Y) -> X - Y end, L, Last_out),

      Zip = lists:zip(Effectors, Errors),
      lists:foreach(fun(P) -> {N, E} = P, N ! {request, self(), {back_error, E}} end, Zip),
      confirm_back_error(Effectors, #{}),

      io:format("Net~w: Errors = ~w ~n", [self(), Errors]),

      Pid ! {reply, self(), {confirm_true_output, ok}},
      loop(Data)

  after
    25000 ->
      true
  end.

