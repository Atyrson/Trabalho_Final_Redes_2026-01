import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it } from "vitest";
import { ChannelGrid } from "./ChannelGrid";

describe("ChannelGrid", () => {
  it("renders backend channel fields without renaming viewer_count", () => {
    render(
      <MemoryRouter>
        <ChannelGrid
          channels={[
            {
              id: 1,
              number: 7,
              name: "Canal Teste",
              description: "Descricao",
              status: "active",
              viewer_count: 3,
            },
          ]}
        />
      </MemoryRouter>,
    );

    expect(screen.getByText("Canal Teste")).toBeInTheDocument();
    expect(screen.getByText("3 espectadores")).toBeInTheDocument();
  });
});
