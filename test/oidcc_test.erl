-module(oidcc_test).
-include_lib("eunit/include/eunit.hrl").

add_openid_provider_test() ->
    MyPid = self(),
    RandomId = <<"6">>,
    AddFun = fun(Id) ->
                     case Id of
                         undefined ->
                             {ok, RandomId, MyPid};
                         Id ->
                             {ok, Id, MyPid}
                     end
                end,
    UpdateFun = fun(_Value,Pid) ->
                        Pid = MyPid,
                        ok
                end,
    ok = meck:new(oidcc_openid_provider),
    ok = meck:new(oidcc_openid_provider_mgr),

    ok = meck:expect(oidcc_openid_provider, set_name, UpdateFun),
    ok = meck:expect(oidcc_openid_provider, set_description, UpdateFun),
    ok = meck:expect(oidcc_openid_provider, set_client_id, UpdateFun),
    ok = meck:expect(oidcc_openid_provider, set_client_secret, UpdateFun),
    ok = meck:expect(oidcc_openid_provider, set_config_endpoint, UpdateFun),
    ok = meck:expect(oidcc_openid_provider, set_local_endpoint, UpdateFun),
    ok = meck:expect(oidcc_openid_provider, update_config, fun(_) -> ok end),

    ok = meck:expect(oidcc_openid_provider_mgr, add_openid_provider, AddFun),

    Name = <<"My Test Oidc">>,
    Id = <<"123345456">>,
    Description = <<"my Test Oidc">>,
    ClientId = <<"123">>,
    ClientSecret = <<"secret">>,
    ConfigEndpoint = <<"some_remote_url">>,
    LocalEndpoint = <<"some_local_url">>,

    {ok, RandomId, MyPid} = oidcc:add_openid_provider(Name,
                                                      Description, ClientId,
                                                      ClientSecret,
                                                      ConfigEndpoint,
                                                      LocalEndpoint),

    {ok, Id, MyPid} = oidcc:add_openid_provider(Id, Name,
                                                      Description, ClientId,
                                                      ClientSecret,
                                                      ConfigEndpoint,
                                                      LocalEndpoint),
    true = meck:validate(oidcc_openid_provider),
    true = meck:validate(oidcc_openid_provider_mgr),
    meck:unload(oidcc_openid_provider),
    meck:unload(oidcc_openid_provider_mgr),
    ok.

get_openid_provider_info_test() ->
    MyPid = self(),
    ProviderId = <<"6">>,
    BadProviderId = <<"7">>,
    ConfigFun = fun(Pid)->
                     Pid = MyPid,
                     {ok, #{}}
                end,
    MapFun = fun(Id) ->
                     case Id of
                         ProviderId -> {ok, MyPid};
                         _ -> {error, not_found}
                     end
             end,
    ok = meck:new(oidcc_openid_provider),
    ok = meck:new(oidcc_openid_provider_mgr),

    ok = meck:expect(oidcc_openid_provider, get_config, ConfigFun),
    ok = meck:expect(oidcc_openid_provider_mgr, get_openid_provider, MapFun),

    {ok, #{}} = oidcc:get_openid_provider_info(MyPid),
    {ok, #{}} = oidcc:get_openid_provider_info(ProviderId),
    {error,not_found} = oidcc:get_openid_provider_info(BadProviderId),

    true = meck:validate(oidcc_openid_provider),
    true = meck:validate(oidcc_openid_provider_mgr),
    meck:unload(oidcc_openid_provider),
    meck:unload(oidcc_openid_provider_mgr),
    ok.

get_openid_provider_list_test() ->
    ListFun = fun() ->
                      {ok, []}
              end,
    ok = meck:new(oidcc_openid_provider_mgr),
    ok = meck:expect(oidcc_openid_provider_mgr, get_openid_provider_list, ListFun),

    {ok, []} = oidcc:get_openid_provider_list(),

    true = meck:validate(oidcc_openid_provider_mgr),
    meck:unload(oidcc_openid_provider_mgr),
    ok.

create_redirect_url_test() ->
    MyPid = self(),
    ProviderId = <<"6">>,
    ClientId = <<"123">>,
    State = <<"someimportantstate">>,
    Nonce = <<"noncenonce">>,

    LocalEndpoint = <<"https://my.server/return">>,
    AuthzEndpoint = <<"https://my.provider/auth">>,

    ConfigFun = fun(Pid)->
                     Pid = MyPid,
                     {ok, #{local_endpoint => LocalEndpoint,
                            client_id => ClientId,
                            authorization_endpoint => AuthzEndpoint
                           }}
                end,
    MapFun = fun(Id) ->
                     case Id of
                         ProviderId -> {ok, MyPid};
                         _ -> {error, not_found}
                     end
             end,
    ok = meck:new(oidcc_openid_provider),
    ok = meck:new(oidcc_openid_provider_mgr),

    ok = meck:expect(oidcc_openid_provider, get_config, ConfigFun),
    ok = meck:expect(oidcc_openid_provider_mgr, get_openid_provider, MapFun),

    {ok, Url1} = oidcc:create_redirect_url(ProviderId),
    {ok, Url2} = oidcc:create_redirect_url(ProviderId,State),
    {ok, Url3} = oidcc:create_redirect_url(ProviderId,State,Nonce),

    ExpUrl1 =
    <<"https://my.provider/auth?response_type=code&scope=openid&client_id=123&redirect_uri=https%3A%2F%2Fmy.server%2Freturn">>,
    Url1 = ExpUrl1,

    ExpUrl2 =
    <<"https://my.provider/auth?response_type=code&scope=openid&client_id=123&redirect_uri=https%3A%2F%2Fmy.server%2Freturn&state=someimportantstate">>,
    Url2 = ExpUrl2,

    ExpUrl3 =
    <<"https://my.provider/auth?response_type=code&scope=openid&client_id=123&redirect_uri=https%3A%2F%2Fmy.server%2Freturn&state=someimportantstate&nonce=noncenonce">>,
    Url3 = ExpUrl3,

    true = meck:validate(oidcc_openid_provider),
    true = meck:validate(oidcc_openid_provider_mgr),
    meck:unload(oidcc_openid_provider),
    meck:unload(oidcc_openid_provider_mgr),
    ok.

retrieve_token_basic_test() ->
    retrieve_token([]).

retrieve_token_post_test() ->
    retrieve_token([<<"unsupporeted_auth">>,<<"client_secret_post">>]).

retrieve_token(AuthMethods) ->
    MyPid = self(),
    ProviderId = <<"6">>,
    ClientId = <<"123">>,
    ClientSecret = <<"secret">>,

    TokenEndpoint = <<"https://my.provider/token">>,
    LocalEndpoint = <<"https://my.server/auth">>,
    HttpBody = <<"TokenRawData">>,
    ConfigFun = fun(Pid)->
                     Pid = MyPid,
                     {ok, #{local_endpoint => LocalEndpoint,
                            client_id => ClientId,
                            client_secret => ClientSecret,
                            token_endpoint => TokenEndpoint,
                            token_endpoint_auth_methods_supported => AuthMethods
                           }}
                end,
    MapFun = fun(Id) ->
                     case Id of
                         ProviderId -> {ok, MyPid};
                         _ -> {error, not_found}
                     end
             end,

    OpenFun = fun(Host, Port, _Config)  ->
                      Host = "my.provider",
                      Port = 443,
                      {ok, gun}
              end,

    PostFun = fun(ConPid, Path, _Header, _Body)  ->
                      Path = "/token",
                      ConPid = gun,
                      gun_stream
              end,
    AwaitFun = fun(ConPid, Stream)  ->
                      ConPid = gun,
                      Stream = gun_stream,
                      {response, nofin, 200, []}
              end,
    AwaitBodyFun = fun(ConPid, Stream)  ->
                      ConPid = gun,
                      Stream = gun_stream,
                      {ok, HttpBody}
              end,
    ok = meck:new(oidcc_openid_provider),
    ok = meck:new(oidcc_openid_provider_mgr),
    ok = meck:new(gun),

    ok = meck:expect(oidcc_openid_provider, get_config, ConfigFun),
    ok = meck:expect(oidcc_openid_provider_mgr, get_openid_provider, MapFun),
    ok = meck:expect(gun, open, OpenFun),
    ok = meck:expect(gun, await_up, fun(_) -> {ok, tcp} end),
    ok = meck:expect(gun, post, PostFun),
    ok = meck:expect(gun, shutdown, fun(_) -> ok end),
    ok = meck:expect(gun, await, AwaitFun),
    ok = meck:expect(gun, await_body, AwaitBodyFun),

    AuthCode = <<"1234567890">>,

    {ok,_} = oidcc:retrieve_token(AuthCode,ProviderId),

    true = meck:validate(oidcc_openid_provider),
    true = meck:validate(oidcc_openid_provider_mgr),
    true = meck:validate(gun),
    meck:unload(oidcc_openid_provider),
    meck:unload(oidcc_openid_provider_mgr),
    meck:unload(gun),
    ok.


parse_and_validate_token_test() ->
    TokenData = <<"TokenData">>,
    IdToken = <<"IdToken">>,
    ProviderId = <<"ID123">>,
    ExtractFun = fun(Data) ->
                         Data = TokenData,
                         #{id => IdToken}
                 end,
    ValidateFun = fun(Data,Provider,_Nonce) ->
                          Provider = ProviderId,
                          Data = IdToken,
                          {ok,#{}}
                  end,

    ok = meck:new(oidcc_token),
    ok = meck:expect(oidcc_token, extract_token_map, ExtractFun),
    ok = meck:expect(oidcc_token, validate_id_token, ValidateFun),

    {ok, #{id := #{}}} = oidcc:parse_and_validate_token(TokenData, ProviderId),

    true = meck:validate(oidcc_token),
    meck:unload(oidcc_token),
    ok.

retrieve_user_info_test() ->
    MyPid = self(),
    ProviderId = <<"6">>,
    UserInfoEndpoint = <<"http://my.provider/info">>,
    HttpBody = <<"{\"name\":\"joe\"}">>,

    ConfigFun = fun(Pid)->
                     Pid = MyPid,
                     {ok, #{userinfo_endpoint => UserInfoEndpoint}}
                end,
    MapFun = fun(Id) ->
                     case Id of
                         ProviderId -> {ok, MyPid};
                         _ -> {error, not_found}
                     end
             end,
    OpenFun = fun(Host, Port, _Config)  ->
                      Host = "my.provider",
                      Port = 80,
                      {ok, gun}
              end,

    GetFun = fun(ConPid, Path, _Header)  ->
                      Path = "/info",
                      ConPid = gun,
                      gun_stream
              end,
    AwaitFun = fun(ConPid, Stream)  ->
                      ConPid = gun,
                      Stream = gun_stream,
                      {response, nofin, 200, []}
              end,
    AwaitBodyFun = fun(ConPid, Stream)  ->
                      ConPid = gun,
                      Stream = gun_stream,
                      {ok, HttpBody}
              end,
    ok = meck:new(oidcc_openid_provider),
    ok = meck:new(oidcc_openid_provider_mgr),
    ok = meck:new(gun),

    ok = meck:expect(oidcc_openid_provider, get_config, ConfigFun),
    ok = meck:expect(oidcc_openid_provider_mgr, get_openid_provider, MapFun),

    ok = meck:expect(gun, open, OpenFun),
    ok = meck:expect(gun, await_up, fun(_) -> {ok, tcp} end),
    ok = meck:expect(gun, get, GetFun),
    ok = meck:expect(gun, shutdown, fun(_) -> ok end),
    ok = meck:expect(gun, await, AwaitFun),
    ok = meck:expect(gun, await_body, AwaitBodyFun),

    Token = #{access => #{token => <<"opensesame">> }},

    {ok, #{name := <<"joe">>} } = oidcc:retrieve_user_info(Token,ProviderId),

    true = meck:validate(gun),
    true = meck:validate(oidcc_openid_provider),
    true = meck:validate(oidcc_openid_provider_mgr),
    meck:unload(gun),
    meck:unload(oidcc_openid_provider),
    meck:unload(oidcc_openid_provider_mgr),
    ok.

