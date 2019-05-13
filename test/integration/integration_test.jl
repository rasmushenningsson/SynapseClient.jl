import SynapseClient: createentity, downloadentity, getentity, updateentity,
                      local_state 
version_check = SynapseClient.synapseclient.version_check.version_check # TODO: put in public API???
SystemExit = pybuiltin(:SystemExit)







































# def test_login():
#     try:
#         # Test that we fail gracefully with wrong user
#         assert_raises(SynapseAuthenticationError, syn.login, 'asdf', 'notarealpassword')

#         config = configparser.ConfigParser()
#         config.read(client.CONFIG_FILE)
#         username = config.get('authentication', 'username')
#         password = config.get('authentication', 'password')
#         sessionToken = syn._getSessionToken(username, password)
        
#         # Simple login with ID + PW
#         syn.login(username, password, silent=True)
        
#         # Login with ID + API key
#         syn.login(email=username, apiKey=base64.b64encode(syn.apiKey), silent=True)
#         syn.logout(forgetMe=True)
        
#         # Config file is read-only for the client, so it must be mocked!
#         if (sys.version < '3'):
#             configparser_package_name = 'ConfigParser'
#         else:
#             configparser_package_name = 'configparser'
#         with patch("%s.ConfigParser.has_option" % configparser_package_name) as config_has_mock, patch("synapseclient.Synapse._readSessionCache") as read_session_mock:

#             config_has_mock.return_value = False
#             read_session_mock.return_value = {}
            
#             # Login with given bad session token, 
#             # It should REST PUT the token and fail
#             # Then keep going and, due to mocking, fail to read any credentials
#             assert_raises(SynapseAuthenticationError, syn.login, sessionToken="Wheeeeeeee")
#             assert config_has_mock.called
            
#             # Login with no credentials 
#             assert_raises(SynapseAuthenticationError, syn.login)
            
#             config_has_mock.reset_mock()
#             config_has_mock.side_effect = lambda section, option: section == "authentication" and option == "sessiontoken"
#             with patch("%s.ConfigParser.get" % configparser_package_name) as config_get_mock:

#                 # Login with a session token from the config file
#                 config_get_mock.return_value = sessionToken
#                 syn.login(silent=True)
                
#                 # Login with a bad session token from the config file
#                 config_get_mock.return_value = "derp-dee-derp"
#                 assert_raises(SynapseAuthenticationError, syn.login)
        
#         # Login with session token
#         syn.login(sessionToken=sessionToken, rememberMe=True, silent=True)
        
#         # Login as the most recent user
#         with patch('synapseclient.Synapse._readSessionCache') as read_session_mock:
#             dict_mock = MagicMock()
#             read_session_mock.return_value = dict_mock
#             dict_mock.__contains__.side_effect = lambda x: x == '<mostRecent>'
#             dict_mock.__getitem__.return_value = syn.username
#             syn.login(silent=True)
#             dict_mock.__getitem__.assert_called_once_with('<mostRecent>')
        
#         # Login with ID only
#         syn.login(username, silent=True)
#         syn.logout(forgetMe=True)
#     except configparser.Error:
#         print("To fully test the login method, please supply a username and password in the configuration file")

#     finally:
#         # Login with config file
#         syn.login(rememberMe=True, silent=True)


# def testCustomConfigFile():
#     if os.path.isfile(client.CONFIG_FILE):
#         configPath='./CONFIGFILE'
#         shutil.copyfile(client.CONFIG_FILE, configPath)
#         schedule_for_cleanup(configPath)

#         syn2 = synapseclient.Synapse(configPath=configPath)
#         syn2.login()
#     else:
#         print("To fully test the login method a configuration file is required")

println(project)
@testset "entity_version" begin
    # Make an Entity and make sure the version is one
    entity = File(parent=project.id)
    entity.path = utils.make_bogus_data_file()
    schedule_for_cleanup(entity.path)
    entity = createentity(syn, entity)
    
    setannotations(syn, entity, Dict("fizzbuzz"=>111222))
    entity = getentity(syn, entity)
    @test entity.versionNumber == 1

    # Update the Entity and make sure the version is incremented
    entity.foo = 998877
    entity.name = "foobarbat"
    entity.description = "This is a test entity..."
    entity = updateentity(syn, entity, incrementVersion=true, versionLabel="Prada remix")
    @test entity.versionNumber == 2

    # Get the older data and verify the random stuff is still there
    annotations = getannotations(syn, entity, version=1)
    @test annotations["fizzbuzz"][1] == 111222
    returnEntity = getentity(syn, entity, version=1)
    @test returnEntity.versionNumber == 1
    @test returnEntity.fizzbuzz[1] == 111222
    @test hasattr(returnEntity,"foo") == false

    # Try the newer Entity
    returnEntity = getentity(syn, entity)
    @test returnEntity.versionNumber == 2
    @test returnEntity.foo[1] == 998877
    @test returnEntity.name == "foobarbat"
    @test returnEntity.description == "This is a test entity..."
    @test returnEntity.versionLabel == "Prada remix"

    # Try the older Entity again
    returnEntity = downloadentity(syn, entity, version=1)
    @test returnEntity.versionNumber == 1
    @test returnEntity.fizzbuzz[1] == 111222
    @test hasattr(returnEntity,"foo") == false
    
    # Delete version 2 
    delete(syn, entity, version=2)
    returnEntity = getentity(syn, entity)
    @test returnEntity.versionNumber == 1
end
@testset "md5_query" begin
    # Add the same Entity several times
    path = utils.make_bogus_data_file()
    schedule_for_cleanup(path)
    repeated = File(path, parent=project.id, description="Same data over and over again")
    
    # Retrieve the data via MD5
    num = 5
    stored = String[]
    for i = 1:num
        repeated.name = "Repeated data $i.dat"
        push!(stored, store(syn,repeated).id)
    end
    # Although we expect num results, it is possible for the MD5 to be non-unique
    results = md5query(syn, utils.md5_for_file(path).hexdigest())
    @test string(sort([res["id"] for res in results])) == string(sort(stored))
    @test length(results) == num
end

@testset "uploadFile_given_dictionary" begin
    # Make a Folder Entity the old fashioned way
    folder = Dict("concreteType"=> SynapseClient.synapseclient.Folder._synapse_entity_type,
            "parentId"  => project.id,
            "name"      => "fooDictionary",
            "foo"       => 334455)
    entity = store(syn, folder)
    
    # Download and verify that it is the same file
    entity = get(syn, entity)
    @test entity.parentId == project.id
    @test entity.foo[1] == 334455

    # Update via a dictionary
    path = utils.make_bogus_data_file()
    schedule_for_cleanup(path)
    rareCase = Dict()
    # rareCase.update(entity.annotations)
    # rareCase.update(entity.properties)
    # rareCase.update(local_state(entity))
    merge!(rareCase,entity.annotations)
    merge!(rareCase,entity.properties)
    merge!(rareCase,local_state(entity))
    rareCase["description"] = "Updating with a plain dictionary should be rare."

    # Verify it works
    entity = store(syn, rareCase)
    @test entity.description == rareCase["description"]
    @test entity.name == "fooDictionary"
    entity = get(syn, entity.id)
end

@testset "uploadFileEntity" begin
    # Create a FileEntity
    # Dictionaries default to FileEntity as a type
    fname = utils.make_bogus_data_file()
    schedule_for_cleanup(fname)
    entity = Dict("name"        => "fooUploadFileEntity",
                  "description" => "A test file entity",
                  "parentId"    => project.id)
    entity = uploadfile(syn, entity, fname)

    # Download and verify
    entity = downloadentity(syn, entity)

    print(entity.files)
    @test entity.files[1] == splitdir(fname)[2]
    # @test filecmp.cmp(fname, entity.path)

    # Check if we upload the wrong type of file handle
    fh = restget(syn, "/entity/$(entity.id)/filehandles")["list"][1]
    @test fh["concreteType"] == "org.sagebionetworks.repo.model.file.S3FileHandle"

    # Create a different temporary file
    fname = utils.make_bogus_data_file()
    schedule_for_cleanup(fname)

    # Update existing FileEntity
    entity = uploadfile(syn, entity, fname)

    # Download and verify that it is the same file
    entity = downloadentity(syn, entity)
    print(entity.files)
    @test entity.files[1] == splitdir(fname)[2]
    # @test filecmp.cmp(fname, entity.path)
end

@testset "test_downloadFile" begin
    # See if the a "wget" works
    filename = utils.download_file("http://dev-versions.synapse.sagebase.org/sage_bionetworks_logo_274x128.png")
    schedule_for_cleanup(filename)
    @test isfile(filename) == true
end

@testset "test_version_check" begin
    # Check current version against dev-synapsePythonClient version file
    version_check(version_url="http://dev-versions.synapse.sagebase.org/synapsePythonClient")

    # Should be higher than current version and return true
    @test version_check(current_version="999.999.999", version_url="http://dev-versions.synapse.sagebase.org/synapsePythonClient") == true

    # Test out of date version
    @test version_check(current_version="0.0.1", version_url="http://dev-versions.synapse.sagebase.org/synapsePythonClient") == false

    # Test blacklisted version
    # @test_pythrows SystemExit version_check(current_version="0.0.0", version_url="http://dev-versions.synapse.sagebase.org/ynapsePythonClient")

    # Test bad URL
    @test version_check(current_version="999.999.999", version_url="http://dev-versions.synapse.sagebase.org/bad_filename_doesnt_exist") == false
end

@testset "provenance" begin
    # Create a File Entity
    fname = utils.make_bogus_data_file()
    schedule_for_cleanup(fname)
    data_entity = store(syn, File(fname, parent=project.id))

    # Create a File Entity of Code
    path = splitext(tempname())[1] * ".py"
    open(path, "w") do f
        write(f, utils.normalize_lines("""
            ## Chris's fabulous random data generator
            ############################################################
            import random
            random.seed(12345)
            data = [random.gauss(mu=0.0, sigma=1.0) for i in range(100)]
            """))
    end
    schedule_for_cleanup(path)
    code_entity = store(syn, File(path, parent=project.id))
    # Create a new Activity asserting that the Code Entity was "used"
    activity = Activity(name="random.gauss", description="Generate some random numbers")
    used(activity, code_entity, wasExecuted=true)
    used(activity, Dict("name"=>"Superhack", "url"=>"https://github.com/joe_coder/Superhack"), wasExecuted=true)
    activity = setprovenance(syn, data_entity, activity)
    
    # Retrieve and verify the saved Provenance record
    retrieved_activity = getprovenance(syn, data_entity)
    @test retrieved_activity == activity

    # Test Activity update
    new_description = "Generate random numbers like a gangsta"
    retrieved_activity["description"] = new_description
    updated_activity = updateactivity(syn, retrieved_activity)
    @test updated_activity["name"] == retrieved_activity["name"]
    @test updated_activity["description"] == new_description

    # Test delete
    deleteprovenance(syn, data_entity)
    @test_pythrows SynapseHTTPError getprovenance(syn,  data_entity.id)
end

@testset "annotations" begin
    # Get the annotations of an Entity
    entity = store(syn, Folder(parent=project.id))
    anno = getannotations(syn, entity)
    @test hasattr(anno, "id")
    @test hasattr(anno, "etag")
    @test anno.id == entity.id
    @test anno.etag == entity.etag

    # Set the annotations, with keywords too
    anno["bogosity"] = "total"
    setannotations(syn, entity, anno, wazoo="Frank", label="Barking Pumpkin", shark=16776960)

    # Check the update
    annote = getannotations(syn, entity)
    @test annote["bogosity"] == ["total"]
    @test annote["wazoo"] == ["Frank"]
    @test annote["label"] == ["Barking Pumpkin"]
    @test annote["shark"] == [16776960]

    # More annotation setting
    # annote["primes"] = [2,3,5,7,11,13,17,19,23,29] # NB: PyCall converts this to array (not list) and synapseclient stores it as an array of strings.
    annote["phat_numbers"] = [1234.5678, 8888.3333, 1212.3434, 6677.8899]
    annote["goobers"] = ["chris", "jen", "jane"]
    annote["present_time"] = now()
    setannotations(syn, entity, annote)
    
    # Check it again
    annotation = getannotations(syn, entity)
    # @test annotation["primes"] == [2,3,5,7,11,13,17,19,23,29] # NB: Disabled because of type problems (see above)
    @test annotation["phat_numbers"] == [1234.5678, 8888.3333, 1212.3434, 6677.8899]
    @test annotation["goobers"] == ["chris", "jen", "jane"]
    # @test annotation["present_time"][1].strftime("%Y-%m-%d %H:%M:%S") == annote["present_time"].strftime("%Y-%m-%d %H:%M:%S")
    @test string(annotation["present_time"][1]) == string(annote["present_time"])
end
@testset "get_user_profile" begin
    p1 = getuserprofile(syn)

    ## get by name
    p2 = getuserprofile(syn, p1["userName"])
    @test p2["userName"] == p1["userName"]

    ## get by user ID
    p2 = getuserprofile(syn, p1["ownerId"])
    @test p2["userName"] == p1["userName"]
end

# @testset "teams" begin
#     unique_name = "Team Gnarly Rad " * string(UUIDs.uuid4())
#     team = Team(name=unique_name, description="A gnarly rad team", canPublicJoin=true)
#     team = store(syn, team)

#     team2 = getteam(syn, team["id"])
#     @test team == team2

#     ## Asynchronously populates index, so wait 'til it's there
#     retry = 0
#     backoff = 0.1
#     while retry < 5
#         retry += 1
#         sleep(backoff)
#         backoff *= 2
#         found_teams = collect(_findteam(syn, team.name))
#         if length(found_teams) > 0
#             break
#         end
#     end
#     @test team == found_teams[1]
#     delete(syn, team)
# end
