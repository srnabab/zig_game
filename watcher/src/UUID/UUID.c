#include "UUID/UUID.h"
#include <windows.h>
#include <rpcdce.h>

bool createNewUUID(unsigned char * uuidStr)
{
    RPC_STATUS status = 0;
    UUID uuid[1];
    RPC_CSTR str = NULL;
    status = UuidCreate(uuid);
    if (status != RPC_S_OK) return false;

    status = UuidToString(uuid, &str);
    if (status != RPC_S_OK) return false;

    memcpy(uuidStr, str, 38);

    (void)RpcStringFree(&str);

    return true;
}
