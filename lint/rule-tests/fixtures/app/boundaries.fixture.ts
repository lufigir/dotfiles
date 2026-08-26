// `no-restricted-imports`, y sobre todo la NEGACIÓN.
//
// El primer import debe reportar. El segundo no, porque `!@/lib/db/client` lo reabre.
// Si el segundo empieza a reportar, las negaciones dejaron de funcionar y toda la
// tabla de boundaries pasó a denegar de más sin avisar. Ese es el fallo silencioso
// que este archivo existe para cazar.

import { serviceRoleClient } from "@/lib/db/admin";
import { browserClient } from "@/lib/db/client"; // CLEAN: la negación `!@/lib/db/client` dejó de reabrir el import legal, así que la tabla de boundaries está denegando de más.

export const usa = serviceRoleClient + browserClient;
