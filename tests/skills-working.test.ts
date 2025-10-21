import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;
const address3 = accounts.get("wallet_3")!;

describe("Skills Tracking System - Core Features", () => {
  it("completes a full workflow with skills registration and management", () => {
    // 1. Register skills
    const skillTech = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "register-skill",
      [Cl.stringAscii("JavaScript"), Cl.uint(1)], // SKILL-TECHNICAL
      address1
    );
    expect(skillTech.result).toBeOk(Cl.uint(1));

    const skillSoft = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "register-skill",
      [Cl.stringAscii("Communication"), Cl.uint(2)], // SKILL-SOFT
      address1
    );
    expect(skillSoft.result).toBeOk(Cl.uint(2));

    const skillLang = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "register-skill",
      [Cl.stringAscii("Spanish"), Cl.uint(3)], // SKILL-LANGUAGE
      address1
    );
    expect(skillLang.result).toBeOk(Cl.uint(3));

    // 2. Test invalid category
    const invalidSkill = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "register-skill",
      [Cl.stringAscii("Invalid"), Cl.uint(5)], // Invalid category
      address1
    );
    expect(invalidSkill.result).toBeErr(Cl.uint(405)); // err-invalid-skill-category

    // 3. Add skill to user profile
    const addSkill = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "add-user-skill",
      [Cl.uint(1), Cl.uint(4)], // JavaScript with proficiency 4
      address2
    );
    expect(addSkill.result).toBeOk(Cl.bool(true));

    // 4. Test invalid proficiency
    const invalidProf = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "add-user-skill",
      [Cl.uint(2), Cl.uint(6)], // Invalid proficiency 6
      address2
    );
    expect(invalidProf.result).toBeErr(Cl.uint(401)); // err-invalid-proficiency

    // 5. Update skill proficiency
    const updateSkill = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "update-skill-proficiency",
      [Cl.uint(1), Cl.uint(5)], // Update to proficiency 5
      address2
    );
    expect(updateSkill.result).toBeOk(Cl.bool(true));

    // 6. Verify skill was registered (skill count should be 3)
    const skillCount1 = simnet.callReadOnlyFn(
      "Job-Application-Tracker-on-Blockchain",
      "get-skill-count",
      [],
      address1
    );
    expect(skillCount1.result).toBeUint(3);

    // 7. Verify user skill was added by checking portfolio
    const portfolio = simnet.callReadOnlyFn(
      "Job-Application-Tracker-on-Blockchain",
      "get-user-skill-portfolio",
      [Cl.principal(address2)],
      address1
    );
    expect(portfolio.result).toBeTuple({ "total-skills": Cl.uint(1) });

    // 8. Register employer and submit application
    const employer = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "register-employer",
      [
        Cl.stringAscii("Tech Corp"),
        Cl.stringAscii("Technology"),
        Cl.stringAscii("Large"),
        Cl.stringAscii("San Francisco"),
        Cl.stringAscii("https://techcorp.com")
      ],
      address1
    );
    expect(employer.result).toBeOk(Cl.uint(1));

    const application = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "submit-application",
      [
        Cl.uint(1), // employer-id
        Cl.stringAscii("Software Engineer"),
        Cl.stringAscii("Tech Corp"),
        Cl.stringAscii("Great opportunity"),
        Cl.uint(120000),
        Cl.stringAscii("San Francisco, CA"),
        Cl.stringAscii("Online"),
        Cl.stringAscii("John Doe")
      ],
      address2
    );
    expect(application.result).toBeOk(Cl.uint(1));

    // 10. Add requirement to application
    const addReq = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "add-application-requirement",
      [Cl.uint(1), Cl.uint(1), Cl.uint(3)], // app-id: 1, skill-id: 1, min-proficiency: 3
      address2
    );
    expect(addReq.result).toBeOk(Cl.bool(true));

    // 11. Verify requirement was added by checking requirements met
    const reqCheck = simnet.callReadOnlyFn(
      "Job-Application-Tracker-on-Blockchain",
      "check-requirements-met",
      [Cl.principal(address2), Cl.uint(1)],
      address1
    );
    expect(reqCheck.result).toBeOk(Cl.bool(true));

    // 12. Remove skill from user
    const removeSkill = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "remove-user-skill",
      [Cl.uint(1)],
      address2
    );
    expect(removeSkill.result).toBeOk(Cl.bool(true));
  });

  it("tests error conditions properly", () => {
    // Test skill not found
    const nonExistentSkill = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "add-user-skill",
      [Cl.uint(999), Cl.uint(3)], // Non-existent skill
      address2
    );
    expect(nonExistentSkill.result).toBeErr(Cl.uint(400)); // err-skill-not-found
  });

  it("tests unauthorized operations", () => {
    // Register a skill and add to user
    simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "register-skill",
      [Cl.stringAscii("Python"), Cl.uint(1)],
      address1
    );

    simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "add-user-skill",
      [Cl.uint(1), Cl.uint(3)],
      address2
    );

    // Try to update from different user - should fail
    const unauthorizedUpdate = simnet.callPublicFn(
      "Job-Application-Tracker-on-Blockchain",
      "update-skill-proficiency",
      [Cl.uint(1), Cl.uint(4)],
      address3 // Different user
    );
    expect(unauthorizedUpdate.result).toBeErr(Cl.uint(400)); // err-skill-not-found for this user
  });
});
