%% -*- coding: utf-8 -*-
%%	porter stemmer for russian language
%%	original algorythm:
%%		http://snowball.tartarus.org/algorithms/russian/stemmer.html
%%
-module(porter_stem_ru).
-export([stem/1, lstem/1]).
-export([rev_and_number/1, rev_and_number_many/1]). % debug
-export([test/0]). % debug

test() ->
	{ok, Data} = file:read_file("deps/porter_stem_ru/test_data"),
	Words = [binary:split(D, <<",">>, [global]) || D <- binary:split(Data, <<"\n">>, [global])],
	TFun = fun(In, MustBe) ->
		Res = stem(In),
		Ok = case Res == unicode:characters_to_list(MustBe) of true -> "OK"; false -> "FAIL" end,
		io:format("TEST ~p:  ~ts result: ~ts must_be: ~ts\n", [Ok, In, Res, MustBe]), timer:sleep(5)
	end,
	[TFun(In, Out) || [In, Out] <- Words],
	ok.

stem(Word) when is_binary(Word) -> sstem(Word); %unicode:characters_to_binary(sstem(Word));
stem(Word) when is_list(Word) -> sstem(Word); %binary_to_list(unicode:characters_to_binary(sstem(Word)));
stem(Word) -> {error, wrong_args, Word}.

sstem(Word) -> lstem(replace_yo_with_ie(unistring:to_lower(unicode:characters_to_list(Word)))).

replace_yo_with_ie(Word) -> replace_yo_with_ie(Word, []).
replace_yo_with_ie([], Acc) -> lists:reverse(Acc);
replace_yo_with_ie([1105 | Rest], Acc) -> replace_yo_with_ie(Rest, [1077 | Acc]);
replace_yo_with_ie([V | Rest], Acc) -> replace_yo_with_ie(Rest, [V | Acc]).

% NOTE! works only with words in lower case!!!
% AND word MUST be result of unicode:characters_to_list(Word)
% AND "ё" must be replaced with "е"
lstem(Word) when is_list(Word) ->
	%% cache??? no cache for now
	%io:format("WORD: ~ts   ~w\n", [Word, Word]),
	case get_rv_part(Word, []) of
		{Start, []} ->
			%io:format("NO V R: ~ts   ~w\n", [Start, Start]),
			Start;
		{Start, RV} ->
			P = lists:reverse(step4(step3(step2(step1(lists:reverse(RV)))))),
			%io:format("YES V R: {~ts, ~ts} {~w, ~w} result: ~ts\n", [Start, P, Start, P, Start++P]),
			Start++P
	end.


get_rv_part([], Acc) -> {lists:reverse(Acc), []};
get_rv_part([1072 | Rest], Acc) -> {lists:reverse([1072 | Acc]), Rest}; % "а"
get_rv_part([1077 | Rest], Acc) -> {lists:reverse([1077 | Acc]), Rest}; % "е"
%get_rv_part([1105 | Rest], Acc) -> {lists:reverse([1105 | Acc]), Rest}; % "ё"
get_rv_part([1080 | Rest], Acc) -> {lists:reverse([1080 | Acc]), Rest}; % "и"
get_rv_part([1086 | Rest], Acc) -> {lists:reverse([1086 | Acc]), Rest}; % "о"
get_rv_part([1091 | Rest], Acc) -> {lists:reverse([1091 | Acc]), Rest}; % "у"
get_rv_part([1099 | Rest], Acc) -> {lists:reverse([1099 | Acc]), Rest}; % "ы"
get_rv_part([1101 | Rest], Acc) -> {lists:reverse([1101 | Acc]), Rest}; % "э"
get_rv_part([1102 | Rest], Acc) -> {lists:reverse([1102 | Acc]), Rest}; % "ю"
get_rv_part([1103 | Rest], Acc) -> {lists:reverse([1103 | Acc]), Rest}; % "я"
get_rv_part([Letter | Rest], Acc) -> get_rv_part(Rest, [Letter | Acc]).


%% PERFECTIVE GERUND
step1([1100, 1089, 1080, 1096, 1074, 1099 | Rest]) -> Rest; % "ывшись" -> ""
step1([1100, 1089, 1080, 1096, 1074, 1080 | Rest]) -> Rest; % "ившись" -> ""
step1([1080, 1096, 1074, 1099 | Rest]) -> Rest; % "ывши" -> ""
step1([1080, 1096, 1074, 1080 | Rest]) -> Rest; % "ивши" -> ""
step1([1074, 1080 | Rest]) -> Rest; % "ив" -> ""

step1([1100, 1089, 1080, 1096, 1074, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % "(а/я)вшись" -> "(а/я)"
step1([1080, 1096, 1074, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % "(а/я)вши" -> "(а/я)"
step1([1074, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % "(а/я)в" -> "(а/я)"

%% REFLEXIVE
step1([1103, 1089 | Rest]) -> step1_2(Rest); %% "ся" -> ""
step1([1100, 1089 | Rest]) -> step1_2(Rest); %% "сь" -> ""
%% ALL OTHER
step1(W) -> step1_2(W).

%% ADJECTIVE 1. it's becauise of pattern matching nature
step1_2([1080, 1084, 1080 | Rest]) -> step1_3(Rest); % ими -> ""
step1_2([1080, 1084, 1099 | Rest]) -> step1_3(Rest); % ыми -> ""
step1_2([1086, 1075, 1077 | Rest]) -> step1_3(Rest); % его -> ""
step1_2([1086, 1075, 1086 | Rest]) -> step1_3(Rest); % ого -> ""
step1_2([1091, 1084, 1077 | Rest]) -> step1_3(Rest); % ему -> ""
step1_2([1091, 1084, 1086 | Rest]) -> step1_3(Rest); % ому -> ""
step1_2([1102, 1102 | Rest]) -> step1_3(Rest); % юю -> ""

%% VERB group1 (а/я) ла, на, ете, йте, ли, й, л, ем, н, ло, но, ет, ют, ны, ть, ешь, нно => (а/я)
step1_2([1077, 1090, 1077, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ете" -> (а/я)
step1_2([1077, 1090, 1081, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "йте" -> (а/я)
step1_2([1100, 1096, 1077, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ешь" -> (а/я)
step1_2([1072, 1083, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ла" -> (а/я)
step1_2([1072, 1085, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "на" -> (а/я)
step1_2([1080, 1083, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ли" -> (а/я)
step1_2([1084, 1077, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ем" -> (а/я)
step1_2([1086, 1083, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ло" -> (а/я)
step1_2([1086, 1085, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "но" -> (а/я)
step1_2([1090, 1077, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ет" -> (а/я)
step1_2([1090, 1102, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ют" -> (а/я)
step1_2([1099, 1085, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ны" -> (а/я)
step1_2([1100, 1090, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "ть" -> (а/я)
step1_2([1085, 1085, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "нн" -> (а/я)
step1_2([1081, V | Rest])             when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "й" -> (а/я)
step1_2([1083, V | Rest])             when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "л" -> (а/я)
step1_2([1085, V | Rest])             when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; % (а/я) "н" -> (а/я)

% VERB group2 ила ыла ена ейте уйте ите или ыли ей уй ил ыл им ым ен ило ыло ено ят ует уют ит ыт ены ить ыть ишь ую ю -> ""
step1_2([1077, 1090, 1081, 1077 | Rest]) -> Rest; % ейте -> ""
step1_2([1077, 1090, 1081, 1091 | Rest]) -> Rest; % уйте -> ""
step1_2([1072, 1083, 1080 | Rest]) -> Rest; % ила -> ""
step1_2([1072, 1083, 1099 | Rest]) -> Rest; % ыла -> ""
step1_2([1072, 1085, 1077 | Rest]) -> Rest; % ена -> ""
step1_2([1077, 1090, 1080 | Rest]) -> Rest; % ите -> ""
step1_2([1080, 1083, 1080 | Rest]) -> Rest; % или -> ""
step1_2([1080, 1083, 1099 | Rest]) -> Rest; % ыли -> ""
step1_2([1086, 1083, 1080 | Rest]) -> Rest; % ило -> ""
step1_2([1086, 1083, 1099 | Rest]) -> Rest; % ыло -> ""
step1_2([1086, 1085, 1077 | Rest]) -> Rest; % ено -> ""
step1_2([1090, 1077, 1091 | Rest]) -> Rest; % ует -> ""
step1_2([1090, 1102, 1091 | Rest]) -> Rest; % уют -> ""
step1_2([1099, 1085, 1077 | Rest]) -> Rest; % ены -> ""
step1_2([1100, 1090, 1080 | Rest]) -> Rest; % ить -> ""
step1_2([1100, 1090, 1099 | Rest]) -> Rest; % ыть -> ""
step1_2([1100, 1096, 1080 | Rest]) -> Rest; % ишь -> ""

step1_2([1081, 1077, 1080 | Rest]) -> Rest; % ией -> "" NOUN

step1_2([1081, 1077 | Rest]) -> Rest; % ей -> ""
step1_2([1081, 1091 | Rest]) -> Rest; % уй -> ""
step1_2([1083, 1080 | Rest]) -> Rest; % ил -> ""
step1_2([1083, 1099 | Rest]) -> Rest; % ыл -> ""
step1_2([1084, 1080 | Rest]) -> Rest; % им -> ""
step1_2([1084, 1099 | Rest]) -> Rest; % ым -> ""
step1_2([1085, 1077 | Rest]) -> Rest; % ен -> ""
step1_2([1090, 1103 | Rest]) -> Rest; % ят -> ""
step1_2([1090, 1080 | Rest]) -> Rest; % ит -> ""
step1_2([1090, 1099 | Rest]) -> Rest; % ыт -> ""
step1_2([1102, 1091 | Rest]) -> Rest; % ую -> ""

% NOUN 1. it's becauise of pattern matching nature
step1_2([1080, 1084, 1103, 1080 | Rest]) -> Rest; % иями -> ""
step1_2([1080, 1084, 1103 | Rest]) -> Rest; % ями -> ""
step1_2([1080, 1084, 1072 | Rest]) -> Rest; % ами -> ""
step1_2([1084, 1103, 1080 | Rest]) -> Rest; % иям -> ""

step1_2([1084, 1077, 1080 | Rest]) -> Rest; % ием -> ""
step1_2([1093, 1103, 1080 | Rest]) -> Rest; % иях -> ""

%% ADJECTIVE 2. ее, ие, ые, ое, ими, ыми, ей, ий, ый, ой, ем, им, ым, ом, его, ого, 
%%	ему, ому, их, ых, ую, юю, ая, яя, ою, ею ->  and pass to PARTICIPLE filter
step1_2([1077, 1077 | Rest]) -> step1_3(Rest); % ее -> ""
step1_2([1077, 1080 | Rest]) -> step1_3(Rest); % ие -> ""
step1_2([1077, 1099 | Rest]) -> step1_3(Rest); % ые -> ""
step1_2([1077, 1086 | Rest]) -> step1_3(Rest); % ое -> ""
%step1_2([1081, 1077 | Rest]) -> step1_3(Rest); % ей -> "" 118
step1_2([1081, 1080 | Rest]) -> step1_3(Rest); % ий -> ""
step1_2([1081, 1099 | Rest]) -> step1_3(Rest); % ый -> ""
step1_2([1081, 1086 | Rest]) -> step1_3(Rest); % ой -> ""
step1_2([1084, 1077 | Rest]) -> step1_3(Rest); % ем -> ""
%step1_2([1084, 1080 | Rest]) -> step1_3(Rest); % им -> "" 122
%step1_2([1084, 1099 | Rest]) -> step1_3(Rest); % ым -> ""
step1_2([1084, 1086 | Rest]) -> step1_3(Rest); % ом -> ""
step1_2([1093, 1080 | Rest]) -> step1_3(Rest); % их -> ""
step1_2([1093, 1099 | Rest]) -> step1_3(Rest); % ых -> ""
%step1_2([1102, 1091 | Rest]) -> step1_3(Rest); % ую -> ""
step1_2([1103, 1072 | Rest]) -> step1_3(Rest); % ая -> ""
step1_2([1103, 1103 | Rest]) -> step1_3(Rest); % яя -> ""
step1_2([1102, 1086 | Rest]) -> step1_3(Rest); % ою -> ""
step1_2([1102, 1077 | Rest]) -> step1_3(Rest); % ею -> ""

% NOUN 2. а ев ов ие ье е иями ями ами еи ии и ией ей ой ий й иям ям ием ем ам ом о у ах иях ях ы ь ию ью ю ия ья я -> ""
step1_2([1074, 1077 | Rest]) -> Rest; % ев -> ""
step1_2([1074, 1086 | Rest]) -> Rest; % ов -> ""
%step1_2([1077, 1080 | Rest]) -> Rest; % ие -> "" 143
step1_2([1077, 1100 | Rest]) -> Rest; % ье -> ""
step1_2([1080, 1077 | Rest]) -> Rest; % еи -> ""
step1_2([1080, 1080 | Rest]) -> Rest; % ии -> ""
%step1_2([1081, 1077 | Rest]) -> Rest; % ей -> "" 118
%step1_2([1081, 1086 | Rest]) -> Rest; % ой -> "" 149
%step1_2([1081, 1080 | Rest]) -> Rest; % ий -> "" 147
step1_2([1084, 1103 | Rest]) -> Rest; % ям -> ""
%step1_2([1084, 1077 | Rest]) -> Rest; % ем -> "" 150
step1_2([1084, 1072 | Rest]) -> Rest; % ам -> ""
%step1_2([1084, 1086 | Rest]) -> Rest; % ом -> ""
step1_2([1093, 1072 | Rest]) -> Rest; % ах -> ""
step1_2([1093, 1103 | Rest]) -> Rest; % ях -> ""
step1_2([1102, 1080 | Rest]) -> Rest; % ию -> ""
step1_2([1102, 1100 | Rest]) -> Rest; % ью -> ""
step1_2([1103, 1080 | Rest]) -> Rest; % ия -> ""
step1_2([1103, 1100 | Rest]) -> Rest; % ья -> ""
step1_2([1103 | Rest]) -> Rest; % я -> ""
step1_2([1072 | Rest]) -> Rest; % а -> ""
step1_2([1077 | Rest]) -> Rest; % е -> ""
step1_2([1080 | Rest]) -> Rest; % и -> ""
step1_2([1081 | Rest]) -> Rest; % й -> ""
step1_2([1086 | Rest]) -> Rest; % о -> ""
step1_2([1091 | Rest]) -> Rest; % у -> ""
step1_2([1099 | Rest]) -> Rest; % ы -> ""
step1_2([1100 | Rest]) -> Rest; % ь -> ""
%step1_2([1102 | Rest]) -> Rest; % ю -> "" 129

%% VERB group3
step1_2([1102 | Rest]) -> Rest; % ю -> ""

%% ALL OTHER
step1_2(W) -> W.

%% PARTICIPLE group1 (а/я) ем нн вш ющ щ => (а/я)
step1_3([1084, 1077, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; %(а/я) ем => (а/я)
step1_3([1085, 1085, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; %(а/я) нн => (а/я)
step1_3([1096, 1074, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; %(а/я) вш => (а/я)
step1_3([1097, 1102, V | Rest]) when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; %(а/я) ющ => (а/я)
step1_3([1097, V | Rest])       when (V =:= 1103) orelse (V =:= 1072) -> [V | Rest]; %(а/я) щ => (а/я)
%% PARTICIPLE group2 ивш ывш ующ -> ""
step1_3([1096, 1074, 1080 | Rest]) -> Rest; % "ивш" -> ""
step1_3([1096, 1074, 1099 | Rest]) -> Rest; % "ывш" -> ""
step1_3([1097, 1102, 1091 | Rest]) -> Rest; % "ующ" -> ""
%% ALL OTHER
step1_3(W) -> W.

% If the word ends with и (i), remove it
step2([1080 | Rest]) -> Rest;
step2(W) -> W.

% DERIVATIONAL ending "ост", "ость" => ""  the entire ending must lie in R2
step3([1100, 1090, 1089, 1086 | Rest] = All) -> remove_if_lies_in_r2_region(Rest, All);
step3([1090, 1089, 1086 | Rest] = All)       -> remove_if_lies_in_r2_region(Rest, All);
step3(W) -> W.

% Cons+ Vowel+ Cons in normal order
%% TEMP. not the best way
remove_if_lies_in_r2_region(R, A) ->
	case re:run(unicode:characters_to_binary(R), "[^аеёиоуыэюя][аеёиоуыэюя]+[^аеёиоуыэюя]", [{capture, none}]) of
		match -> R;
		nomatch -> A
	end.

% SUPERLATIVE ейш, ейше -> ""
step4([1077, 1096, 1081, 1077 | Rest]) -> step4(Rest); % "ейше" -> ""
step4([1096, 1081, 1077 | Rest]) -> step4(Rest); % "ейш" -> ""
step4([1085, 1085 | Rest]) -> [1085 | Rest]; % "нн" -> "н" !!!
step4([1100 | Rest]) -> Rest; % "ь" -> ""
step4(W) -> W.



%% DEBUG. you put part of string like "ивш" and gets utf8 codes in REVERSE order like [1080, 1074, 1096]
rev_and_number_many(Words) ->
	[rev_and_number(Word) || Word <- Words].

rev_and_number(Word) ->
	Chars = unicode:characters_to_list(Word),
	[io:format("~p, ", [V]) || V <- lists:reverse(Chars)],
	io:format("\n").
