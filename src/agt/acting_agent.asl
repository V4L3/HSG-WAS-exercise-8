// acting agent

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://ci.mines-stetienne.fr/kg/ontology#PhantomX
robot_td("https://raw.githubusercontent.com/Interactions-HSG/example-tds/main/tds/leubot1.ttl").

/* Initial beliefs and rules */

role_goal(R, G) :-
	role_mission(R, _, M) & mission_goal(M, G).

can_achieve (G) :-
	.relevant_plans({+!G[scheme(_)]}, LP) & LP \== [].

i_have_plans_for(R) :-
       not (role_goal(R, G) & not can_achieve(G)).

role_available(R) :- 
		role_cardinality(R, Min, Max) & 
		.count(play(_,R,_),NumberOfAgents) & 
		Max > NumberOfAgents.

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.print("Hello world").

+new_organisation(Workspace, Artifact) : true <-
	joinWorkspace(Workspace, WspID1);
	lookupArtifact(Artifact, OrgArtId);
	focus(OrgArtId);
	.print("focused on Organisation").

+new_group(GrpName) : true <-
	lookupArtifact(GrpName, GrpArtId);
	focus(GrpArtId);
	.print("focused on Group: ", GrpName);
	!check_for_open_roles(GrpArtId).

+!check_for_open_roles(GrpArtId) : role(R,G) & role_available(R) & i_have_plans_for(R) <-
  .print("Found open role: ", R);
  adoptRole(R).

+!check_for_open_roles(GrpArtId) : role(R,G) & not role_available(R) & i_have_plans_for(R) <-
  .print("Found open role, but it is not available: ", R).

+!check_for_open_roles(GrpArtId) : role(R,G) & role_available(R) & not i_have_plans_for(R) <-
  .print("Found open role, but I do not have plans for it: ", R).

/* 
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that there is a temperature in Celcius and
 * that a WoT TD of an onto:PhantomX is located at Location
 * Body: converts the temperature from Celcius to binary degrees that are compatible with the 
 * movement of the robotic arm. Then, manifests the temperature with the robotic arm
*/
@manifest_temperature_plan 
+!manifest_temperature : temperature(Celcius) & robot_td(Location) <-
	.print("I will manifest the temperature: ", Celcius);
	makeArtifact("covnerter", "tools.Converter", [], ConverterId); // creates a converter artifact
	convert(Celcius, -20.00, 20.00, 200.00, 830.00, Degrees)[artifact_id(ConverterId)]; // converts Celcius to binary degress based on the input scale
	.print("Temperature Manifesting (moving robotic arm to): ", Degrees);

	/* 
	 * If you want to test with the real robotic arm, 
	 * follow the instructions here: https://github.com/HSG-WAS-SS23/exercise-8/blob/main/README.md#test-with-the-real-phantomx-reactor-robot-arm
	 */
	// creates a ThingArtifact based on the TD of the robotic arm
	// makeArtifact("leubot1", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Location, true], Leubot1Id); 
	makeArtifact("leubot1", "wot.ThingArtifact", [Location, true], Leubot1Id); 
	// sets the API key for controlling the robotic arm as an authenticated user
	//setAPIKey("77d7a2250abbdb59c6f6324bf1dcddb5")[artifact_id(leubot1)];

	// invokes the action onto:SetWristAngle for manifesting the temperature with the wrist of the robotic arm
	invokeAction("https://ci.mines-stetienne.fr/kg/ontology#SetWristAngle", ["https://www.w3.org/2019/wot/json-schema#IntegerSchema"], [Degrees])[artifact_id(leubot1)].

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }
