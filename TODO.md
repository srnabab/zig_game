1. function executeCommands: skip most of code when nodeDag is empty or only have start node (maybe)
2. add feature: register pipeline
3. process pushconstant with pipeline
4. do statistics for memory pool allocate times and init with capacity
<!-- 5. use libgit to reduce useless compile --> (done with zig hash)
6. encapsulate steam api
<!-- 7. add feature: pipeline pushconstant json generator exclude duplicated pipeline name -->
8. shader change should change .pipe file
9. remove non-exist pushconstant in json file
10. prase push constant json file to struct
11. 3 steps pipeline and shader compile operation: 
    1. select modified file to txt but do not modify cache.json
    2. do compile, remove successful file name from txt
    3. read txt and modify cache.json
12. complete addCommand .graphic
13. change texture set implement from **memory pool + hash map** to **array + extra process + hash map**
14. refactor VkStruct.zig
15. add offsets to texture set 
16. function offsetsAdd can optimize by analyse branch
