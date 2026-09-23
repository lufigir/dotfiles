// Una policy es pura. Este import debe reportar: `next/*` está cerrado.
import { revalidatePath } from "next/cache";

export const puedeVer = () => {
  revalidatePath("/");
  return true;
};
